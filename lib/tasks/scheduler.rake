# "This task is called by the Heroku scheduler add-on"
task :update_mailchimp => :environment do

  # pour tester en dev changer Time.now.wday != 5 et Recommendation.where(user_id: 553).each do |reco|, et ne le faire que sur un user, pas la peine de le faire sur User.all

# Verifier si on est vendredi matin (on fera le rake sur Heroku tous les jours très tot)
# Hors test, mettre == 5, sinon à moins d'etre vendredi il ne se passera rien
  if Time.now.wday == 4
    puts "Updating mailchimp infos ..."
    # ok: isoler un user
    User.all.each do |user|

      if user.newsletter_updated == false

        puts "Updating #{user.name}"

        # Récupérer la liste des restaurants, hormis Needl et hormis ceux que j'ai déjà recommandé, recommandés par mes amis au cours du mois
        restaurants_ids = my_friends_except_needl_and_me_this_month_restaurants_ids(user)
        puts "les restos dans le dernier mois de mes amis: #{restaurants_ids}"

        # Récupérer la sélection de types que l'on va checker.A la base c'est  Burger - Thaï - Japonais - Italien - Français - Street Food - Oriental - Pizza et on retire ceux qui sont déjà tombés.

        fetching_types_used(user)
        types_selection_ids = [11, 2, 5, 9, 8, 12, 17, 15, 10] - @types_already_used
        puts "Les types associés: #{types_selection_ids}"

        # Récupérer le premier thème où plus de 2 recos d'amis

        type_selected_id = return_type_selected_id(types_selection_ids, restaurants_ids)
        puts "Le type choisi pour la newsletter: #{type_selected_id}"

        # On vérifie qu'il ya bien eu une catégorie pour laquelle l'utilisateur a eu 2 recos dans le mois
        if type_selected_id != ""

          # On récupère les restaurants concernés
          restaurants_on_type = Restaurant.joins(:types).where(types: {id: type_selected_id}, restaurants: {id: restaurants_ids})
          puts "Les restaurants de tes amis: #{restaurants_on_type}"

          # On récupère les 2 ou 3 max recos de restaurants les plus fraiches
          final_recommendations = select_fresh_recommendations_in_type_selected(user, restaurants_on_type)
          puts "les recos qui paraitront de tes amis: #{final_recommendations}"

          # S'il n'y en a que 2, on en met une de Needl
          if final_recommendations.length == 2
            @array = [final_recommendations[0].restaurant_id, final_recommendations[1].restaurant_id]
            reco_needl = reco_from_needl(type_selected_id)
            puts "la reco needl: #{reco_needl}"
            final_recommendations << reco_needl
            puts "la selection finale de recos: #{final_recommendations}"
          end

        else
          # on refait la même manip avec les restos de Needl except me uniquement
          type_selected_id = types_selection_ids.first
          puts "le type sélectionné: #{type_selected_id}"
          @array = []
          final_recommendations = [reco_from_needl(type_selected_id), reco_from_needl(type_selected_id), reco_from_needl(type_selected_id)]
          puts "la selection finale de recos: #{final_recommendations}"

        end



        # On retient le thème pris pour qu'il ne retombe pas pour le user
        @types_already_used << type_selected_id
        puts "on récapitule les types déjà utilisés: #{@types_already_used.map(&:to_s)}"
        user.update_attributes(newsletter_themes: @types_already_used.map(&:to_s))
        user.update_attributes(newsletter_updated: true)
        user.save
        puts "La colomne newsletter themes actualisée pour le user"

        # On envoie les infos à Mailchimp
        send_mailchimp_the_updates(user, type_selected_id, final_recommendations[0], final_recommendations[1], final_recommendations[2])
        puts "Data envoyée à mailchimp"

      else
        user.newsletter_updated = false
        user.save
        puts "#{user.name} already updated"

        # On envoie les infos à Mailchimp
        send_mailchimp_newsletter_not_updated(user)
        puts "Data envoyée à mailchimp"

      end

    end

  else
    puts "Nothing Today."
  end
  puts "done."


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

task :update_needl_coefficients => :environment do
  if Time.now.wday == 3
    Restaurant.all.each do |restaurant|
      restaurant.needl_coefficient = 0
      if restaurant.recommendations.where(user_id: 553).length > 0
        restaurant.needl_coefficient = rand(1..5)
      end
      restaurant.save
    end
  end
end

task :update_taste_correspondes => :environment do
  User.all.each do |user1|
    user1_restaurants_ids = user1.my_restaurants_ids
    TasteCorrespondence.where(member_one_id: user1.id).each do |taste_correspondence|
      user2_restaurants_ids = user2.my_restaurants_ids
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






def my_friends_except_needl_and_me_this_month_restaurants_ids(user)
  # On récupère tous les amis sauf needl
  user_ids = user.my_visible_friends_ids

  # On récupère tous les restaurants recommandés dans le mois
  restaurants_ids = Restaurant.joins(:recommendations).where(recommendations: {created_at: (Time.now - 1.month)..Time.now, user_id: user_ids }).pluck(:id).uniq
  # On enlève les miens, car ça perdrait de son interet pour moi de les avoir dans la newsletter
  restaurants_ids -= user.my_restaurants_ids

  return restaurants_ids

end

def fetching_types_used(user)
  @types_already_used = user.newsletter_themes == nil ? [] : user.newsletter_themes.map(&:to_i)
  # S'ils sont tous tombés et dans ce cas on reprend à 0. La longueur de 9 peut évoluer, attention !!
  if @types_already_used.length == 9
    user.update_attributes(newsletter_themes: nil)
    user.save
    @types_already_used = []
  end
  puts "types déjà utilisés : #{@types_already_used}"
end

def return_type_selected_id(types_selection_ids, restaurants_ids)
  types_ids = Type.joins(:restaurants).where(restaurants: {id: restaurants_ids}).pluck(:id)
  types_selection_ids.each do |type_id|
    return type_id if types_ids.count(type_id) >= 2
  end
  return ""
end

def select_fresh_recommendations_in_type_selected(user, restaurants_on_type)
  # Pour chaque restaurant du bon type, on récupère la recommandation la plus fraiche avec un commentaire s'il y a
  final_recommendations = []
  restaurants_on_type.each do |restaurant|
    recommendations = restaurant.recommendations.where(user_id: user.my_visible_friends_ids).order('created_at DESC')
    recommendations_reviewed = recommendations.where("review != ?", "Je recommande !")
    recommendation = Recommendation.new
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

def reco_from_needl(type_selected_id)
  # il faudra mettre 40 en développement !!
  Recommendation.where(user_id: 553).each do |reco|
    restaurant_id = reco.restaurant_id
    if Restaurant.find(restaurant_id).types.first.id == type_selected_id && @array.exclude?(restaurant_id)
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

  resto1 = reco1 != "" ? Restaurant.find(reco1.restaurant_id) : ""
  resto2 = reco2 != "" ? Restaurant.find(reco2.restaurant_id) : ""
  resto3 = reco3 != "" ? Restaurant.find(reco3.restaurant_id) : ""
  # photo1 = resto1.restaurant_pictures.first ? resto1.restaurant_pictures.first.picture.url : resto1.picture_url
  # photo1 = (photo1 == "restaurant_default.jpg") ? "" : photo1
  # photo2 = resto2.restaurant_pictures.first.picture.url : resto2.picture_url
  # photo2 = (photo2 == "restaurant_default.jpg") ? "" : photo2
  # photo3 = resto3.restaurant_pictures.first ? resto3.restaurant_pictures.first.picture.url : resto3.picture_url
  # photo3 = (photo3 == "restaurant_default.jpg") ? "" : photo3
  # Si c'est aussi moche c'est pour que ca remplisse en vide s'il n'y a pas assez de restaurants de la part de Needl

  gibbon.lists(list_id).members(mail_encrypted).upsert(
    body: {
      merge_fields: {
        UPDATED: user.newsletter_updated,
        THEME: reco1 != "" ? Type.find(type_selected_id).name : "",
        REST1NAME: reco1 != "" ? resto1.name : "",
        REST1TYPE: reco1 != "" ? resto1.types.first.name : "",
        REST1METRO: reco1 != "" ? resto1.subway_name : "",
        REST1FR: reco1 != "" ? User.find(reco1.user_id).name : "",
        REST1REV: reco1 != "" ? reco1.review : "",
        REST1ID: reco1 != "" ? resto1.id : "",
        REST1IMG: reco1 != "" ? resto1.restaurant_pictures.first ? resto1.restaurant_pictures.first.picture.url : resto1.picture_url : "",
        REST2NAME: reco2 != "" ? resto2.name : "",
        REST2TYPE: reco2 != "" ? resto2.types.first.name : "",
        REST2METRO: reco2 != "" ? resto2.subway_name : "",
        REST2FR: reco2 != "" ? User.find(reco2.user_id).name : "",
        REST2REV: reco2 != "" ? reco2.review : "",
        REST2ID: reco2 != "" ? resto2.id : "",
        REST2IMG: reco2 != "" ? resto2.restaurant_pictures.first ? resto2.restaurant_pictures.first.picture.url : resto2.picture_url : "",
        REST3NAME: reco3 != "" ? resto3.name : "",
        REST3TYPE: reco3 != "" ? resto3.types.first.name : "",
        REST3METRO: reco3 != "" ? resto3.subway_name : "",
        REST3FR: reco3 != "" ? User.find(reco3.user_id).name : "",
        REST3REV: reco3 != "" ? reco3.review : "",
        REST3ID: reco3 != "" ? resto3.id : "",
        REST3IMG: reco3 != "" ? resto3.restaurant_pictures.first ? resto3.restaurant_pictures.first.picture.url : resto3.picture_url : ""
      }
    }
  )

end

def send_mailchimp_newsletter_not_updated(user)
  mail_encrypted = Digest::MD5.hexdigest(user.email)
  gibbon = Gibbon::Request.new(api_key: ENV['MAILCHIMP_API_KEY'])
  list_id = ENV['MAILCHIMP_LIST_ID_NEEDL_USERS']

  gibbon.lists(list_id).members(mail_encrypted).upsert(
    body: {
      merge_fields: {
        UPDATED: user.newsletter_updated
      }
    }
  )
end