# "This task is called by the Heroku scheduler add-on"
task :update_mailchimp => :environment do


  User.all.each do |user|

    # le token on l'enlèvera quand les gens pourront s'inscrire par mail
    if user.email.include?("needlapp.com") == false && (Time.now - user.created_at)/3600 > 9 && user.token

      puts "utilisateur #{user.name}, #{user.id}"

      @my_visible_friends_ids = user.my_visible_friends_ids
      @my_experts_ids         = user.followings.pluck(:id)
      # ne sert à rien d'actualiser la newsletter de ceux qui n'ont pas d'adresse mail. De plus on ne l'envoie que à ceux qui sont inscrit depuis 10 jours donc pas la peine de le faire pour ceux inscrits depuis moins de 9 jours

      # Récupérer la liste de tous les restaurants recommandés par mes gens de confiance
      restaurants_ids = my_friends_and_experts_restaurants_ids(user)

      # Récupérer la sélection de types que l'on va checker.A la base c'est  Burger - Thaï - Japonais - Italien - Français - Oriental - Pizza et on retire ceux qui sont déjà tombés.
      types_selection_ids = [11, 2, 5, 9, 8, 15, 10] - fetching_types_used(user)

      # On récupère tous les thèmes où il y a au moins 3 recos

      potential_types = all_potential_types(types_selection_ids, restaurants_ids)
      puts "potential_types #{potential_types}"

      if potential_types.length > 0
      # On ordonne les types par le nombre de recos par des amis

        restaurants_from_friends = {}
        potential_types.each do |type_id|
          restaurants_on_type = Restaurant.joins(:types).where(types: {id: type_id}, restaurants: {id: restaurants_ids})
          restaurants_on_type.each do |restaurant|
            restaurants_from_friends[type_id] ||= []
            if restaurant.recommendations.where(user_id: @my_visible_friends_ids).length > 0
              restaurants_from_friends[type_id] << restaurant.id
            end
          end

        end

        puts "restaurants_on_type_from_friends: #{restaurants_from_friends}"
        type_selected_id = Hash[restaurants_from_friends.sort_by {|k, v| v.length}.reverse].first.first
        restaurants_on_type_from_friends_ids = Hash[restaurants_from_friends.sort_by {|k, v| v.length}.reverse].first[1]

        # je récupère toutes les recos de mes amis

        restaurants_on_type_from_friends = Restaurant.where(id: restaurants_on_type_from_friends_ids)
        final_recommendations = select_recommendations_from_friends_in_type_selected(user, restaurants_on_type_from_friends)

        # Je les complète par celles de mes experts

        case final_recommendations.length
        when 0
          @array = []
          final_recommendations += [reco_from_experts(user, type_selected_id, restaurants_ids), reco_from_experts(user, type_selected_id, restaurants_ids ), reco_from_experts(user, type_selected_id, restaurants_ids ) ]
        when 1
          @array = [final_recommendations[0].restaurant_id]
          final_recommendations += [reco_from_experts(user, type_selected_id, restaurants_ids), reco_from_experts(user, type_selected_id, restaurants_ids)]
        when 2
          @array = [final_recommendations[0].restaurant_id, final_recommendations[1].restaurant_id ]
          final_recommendations += [reco_from_experts(user, type_selected_id, restaurants_ids)]
        when 3
          @array = [final_recommendations[0].restaurant_id, final_recommendations[1].restaurant_id, final_recommendations[2].restaurant_id ]
        end

        # On envoie les infos à Mailchimp, mais il faut tester qu'on en a bien trois !
        send_mailchimp_the_updates(user, type_selected_id, final_recommendations[0], final_recommendations[1], final_recommendations[2])

        # On retient le thème pris pour qu'il ne retombe pas pour le user
        user.newsletter_themes << type_selected_id
        user.newsletter_restaurants += [final_recommendations[0].restaurant_id, final_recommendations[1].restaurant_id, final_recommendations[2].restaurant_id]
        user.save

      else

        reset_mailchimp_to_zero(user)

      end

    end

  end

end


task :import_contacts => :environment do

  users = User.all

  ImportedContact.where(imported: false).each do |import|

    list = import.list

    users.each do |user|

      list.each do |contact|

        # on met les numéros récupérés au meme format
        phone_numbers = []
        if contact["phoneNumbers"]
          phone_numbers = contact["phoneNumbers"].map do |x|
            n = x["number"].gsub(/[^0-9+]/, '')
            n = n.gsub(/^00/,"+")
            n = n.gsub(/^0/,"+33")
          end
        end
        user_phone_numbers = user.phone_numbers
        emails = contact["emailAddresses"] ? contact["emailAddresses"].map{|x| x["email"].downcase.delete(' ')} : []
        user_emails = user.emails

        # On test si on reconnait le user grace aux numéros de tel ou a une adresse mail
        if phone_numbers.any? {|number| user_phone_numbers.include?(number) } || emails.any? {|email| user_emails.include?(email) }
          # on rajoute des mails si pas dans la BDD
          emails.each do |email|
            if user_emails.include?(email) == false
              user_emails << email
              user.save
            end
          end

          # on rajoute des tels si pas dans la BDD
          phone_numbers.each do |number|
            if user_phone_numbers.include?(number) == false
              user_phone_numbers << number
              user.save
            end
          end

        end

      end

    end

    import.update_attribute :imported, true
    import.save
  end

end

task :update_taste_correspondences => :environment do
  User.all.each do |user1|
    user1_restaurants_ids = user1.my_restaurants_ids
    TasteCorrespondence.where(member_one_id: user1.id).each do |taste_correspondence|
      user2_restaurants_ids = User.find(taste_correspondence.member_two_id).my_restaurants_ids
      number_of_shared_restaurants = (user1_restaurants_ids & user2_restaurants_ids).length
      case number_of_shared_restaurants
        when 0..4
          taste_correspondence.category = 1
        when 5..8
          taste_correspondence.category = 2
        else
          taste_correspondence.category = 3
      end
      taste_correspondence.number_of_shared_restaurants = number_of_shared_restaurants
      taste_correspondence.save
    end

  end

end


def my_friends_and_experts_restaurants_ids(user)

  restaurants_ids = Restaurant.joins(:recommendations).where(recommendations: {user_id: @my_visible_friends_ids}).pluck(:id)
  restaurants_ids += Restaurant.joins(:recommendations).where(recommendations: {user_id: @my_experts_ids , public: true }).pluck(:id)
  restaurants_ids = restaurants_ids.uniq
  # On enlève les miens, car ça perdrait de son interet pour moi de les avoir dans la newsletter
  restaurants_ids -= user.my_restaurants_ids
  restaurants_ids -= user.newsletter_restaurants

  return restaurants_ids

end


def fetching_types_used(user)
  # S'ils sont tous tombés et dans ce cas on reprend à 0. La longueur de 9 peut évoluer, attention !!
  if user.newsletter_themes.length == 7
    user.update_attributes(newsletter_themes: [])
    user.save
  end
  return user.newsletter_themes
end

def all_potential_types(types_selection_ids, restaurants_ids)
  types_ids = Type.joins(:restaurants).where(restaurants: {id: restaurants_ids}).pluck(:id)
  potential_types = []
  types_selection_ids.each do |type_id|
    potential_types << type_id if types_ids.count(type_id) >= 3
  end
  potential_types
end

def select_recommendations_from_friends_in_type_selected(user, restaurants_on_type_from_friends)
  # Pour chaque restaurant du bon type, on récupère la recommandation la plus fraiche avec un commentaire s'il y a
  final_recommendations = []
  restaurants_on_type_from_friends.each do |restaurant|
    recommendations = restaurant.recommendations.where(user_id: @my_visible_friends_ids).order('created_at DESC')
    recommendations_reviewed = recommendations.where("review != ?", "Je recommande !")
    if recommendations_reviewed.length > 0
      recommendation = recommendations_reviewed.first
      final_recommendations << recommendation
    else
      recommendation = recommendations.first
      final_recommendations << recommendation
    end
  end
  return final_recommendations.sort_by{|element| element.created_at}.reverse.first(3)
end

def reco_from_experts(user, type_selected_id, restaurants_ids)

  Recommendation.joins(restaurant: :restaurant_types).where(user_id: @my_experts_ids, public: true, restaurant_types: {type_id: type_selected_id}, restaurants: {id: restaurants_ids}).each do |reco|
    if @array.exclude?(reco.restaurant_id)
      # cette ligne c'est pour qu'il ne choisisse pas un resto deja choisi
      @array << reco.restaurant_id
      return reco
    end
  end
  return ""
end

def send_mailchimp_the_updates(user, type_selected_id, reco1, reco2, reco3)
  mail_encrypted = Digest::MD5.hexdigest(user.email.downcase)
  gibbon = Gibbon::Request.new(api_key: ENV['MAILCHIMP_API_KEY'])
  list_id = ENV['MAILCHIMP_LIST_ID_NEEDL_USERS']

  resto1 = Restaurant.find(reco1.restaurant_id)
  resto2 = Restaurant.find(reco2.restaurant_id)
  resto3 = Restaurant.find(reco3.restaurant_id)

  theme  = Type.find(type_selected_id).name
  case theme
  when "Français"
    theme = "restos français"
  when "Italien"
    theme = "restos italiens"
  when "Japonais"
    theme = "restos japonais"
  when "Thaï"
    theme = "restos thaï"
  when "Oriental"
    theme = "restos orientaux"
  when "Pizza"
    theme = "pizzerias"
  end

  # ici dans thème on va pouvoir changer chaque semaine le nom du thème suivant l'ID pour faire des beaux titres de mail

  gibbon.lists(list_id).members(mail_encrypted).upsert(
    body: {
      merge_fields: {
        THEME: theme,
        REST1NAME: resto1.name,
        REST1METRO: resto1.subway_name,
        REST1FR: User.find(reco1.user_id).name,
        REST1REV: reco1.review,
        REST1ID: resto1.id,
        REST1IMG: resto1.restaurant_pictures.first ? resto1.restaurant_pictures.first.picture.url : resto1.picture_url,
        REST2NAME: resto2.name,
        REST2METRO: resto2.subway_name,
        REST2FR: User.find(reco2.user_id).name,
        REST2REV: reco2.review,
        REST2ID: resto2.id,
        REST2IMG: resto2.restaurant_pictures.first ? resto2.restaurant_pictures.first.picture.url : resto2.picture_url,
        REST3NAME: resto3.name,
        REST3METRO: resto3.subway_name,
        REST3FR: User.find(reco3.user_id).name,
        REST3REV: reco3.review,
        REST3ID: resto3.id,
        REST3IMG: resto3.restaurant_pictures.first ? resto3.restaurant_pictures.first.picture.url : resto3.picture_url
      }
    }
  )

end

def reset_mailchimp_to_zero(user)
  mail_encrypted = Digest::MD5.hexdigest(user.email.downcase)
  gibbon = Gibbon::Request.new(api_key: ENV['MAILCHIMP_API_KEY'])
  list_id = ENV['MAILCHIMP_LIST_ID_NEEDL_USERS']


  gibbon.lists(list_id).members(mail_encrypted).upsert(
    body: {
      merge_fields: {
        THEME: "",
        REST1NAME: "",
        REST1METRO: "",
        REST1FR: "",
        REST1REV: "",
        REST1ID: "",
        REST1IMG: "",
        REST2NAME: "",
        REST2METRO: "",
        REST2FR: "",
        REST2REV: "",
        REST2ID: "",
        REST2IMG: "",
        REST3NAME: "",
        REST3METRO: "",
        REST3FR: "",
        REST3REV: "",
        REST3ID: "",
        REST3IMG: ""
      }
    }
  )





end




