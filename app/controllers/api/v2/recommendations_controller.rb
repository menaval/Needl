class Api::V2::RecommendationsController < ApplicationController
  acts_as_token_authentication_handler_for User
  skip_before_action :verify_authenticity_token
  skip_before_filter :authenticate_user!

  require 'twilio-ruby'
  require 'open-uri'
  require 'nokogiri'
  require 'json'

  def index
    @user = User.find_by(authentication_token: params["user_token"])
    @tracker.track(@user.id, 'notif_page', { "user" => @user.name })
  end

  def create

    @user = User.find_by(authentication_token: params["user_token"])
    if params["restaurant_id"].length <= 9 && Recommendation.where(restaurant_id:params["restaurant_id"].to_i, user_id: @user.id).length > 0
      update(params["restaurant_id"], @user.id)
    else
      identify_or_create_restaurant

      # On crée la recommandation à partir des infos récupérées
      new_params = recommendation_params
      new_params["review"] = recommendation_params["review"] ? recommendation_params["review"] : "Je recommande !"
      new_params["friends_thanking"] = recommendation_params["friends_thanking"] ? recommendation_params["friends_thanking"].map{|x| x.to_i} : []
      new_params["experts_thanking"] = recommendation_params["experts_thanking"] ? recommendation_params["experts_thanking"].map{|x| x.to_i} : []
      puts "------------------------------------------------------------------------------------------------"
      puts "params: #{recommendation_params}"
      @recommendation = @user.recommendations.new(new_params)
      @recommendation.restaurant = @restaurant
      @recommendation.save
      @tracker.track(@user.id, 'New Reco', { "restaurant" => @restaurant.name, "user" => @user.name })

      # on redirige vers les actions de remerciement
      if params["friends_thanking"] != []
        thank_friends(@recommendation.friends_thanking)
      end

      if params["experts_thanking"] != []
        thank_experts(@recommendation.experts_thanking)
      end
      # attention on ne l'envoie plus à ceux qui ont été remerciés (pas besoin de checker si different du vide on le fait rapidement apres)
      notif_reco(params["friends_thanking"])

      # si c'était sur ma liste de wish ça l'enlève
      if Wish.where(restaurant_id:params["restaurant_id"].first(5).to_i, user_id: @user.id).any?
        Wish.where(restaurant_id:params["restaurant_id"].first(5).to_i, user_id: @user.id).first.destroy
        @tracker.track(@user.id, 'Wish to Reco', { "restaurant" => @restaurant.name, "user" => @user.name })
      end
      # si première recommandation, alors envoie un mail à tous ses potes
      if @user.recommendations.count == 1
        tell_all_friends
      end

      # on renvoie le restaurant et l'activité
      restaurant_info = JSON(Nokogiri.HTML(open("http://www.needl.fr/api/v2/restaurants/#{@recommendation.restaurant_id}.json?user_email=#{@user.email}&user_token=#{@user.authentication_token}")))
      restaurant_info.each { |k, v| restaurant_info[k] = v.encode("iso-8859-1").force_encoding("utf-8") if v.class == String }

        render json: {
          restaurant: restaurant_info,
          activity: {user_id: @user.id, restaurant_id: @recommendation.restaurant_id, user_type: "me", notification_type: "recommendation", review: @recommendation.review, date: @recommendation.created_at, strengths: @recommendation.strengths, ambiences: @recommendation.ambiences, occasions: @recommendation.occasions, friends_thanking: @recommendation.friends_thanking, experts_thanking: @recommendation.experts_thanking}
        }
    end
  end

  def destroy
    @user = User.find_by(authentication_token: params["user_token"])
    reco = Recommendation.where(restaurant_id: params["id"].to_i, user_id: @user.id).first
    if PublicActivity::Activity.where(trackable_type: "Recommendation", trackable_id: reco.id).length > 0
      activity = PublicActivity::Activity.where(trackable_type: "Recommendation", trackable_id: reco.id).first
      activity.destroy
    end
    # il faut unthank les friends et les experts
    unthank_friends(reco.friends_thanking)
    unthank_experts(reco.experts_thanking)
    reco.destroy

    redirect_to api_v2_restaurant_path(id: params["id"].to_i, :user_email => params["user_email"], :user_token => params["user_token"], :notice => "Le restaurant a bien été retiré de vos recommandations"), status: 303
  end

  def update(restaurant_id = 0, user_id = 0)
    @user = User.find_by(authentication_token: params["user_token"])
    puts "----------------------------------------------------------------------------"
    puts "user : #{@user}"
    if restaurant_id == 0
      @recommendation = Recommendation.where(restaurant_id: params["id"].to_i, user_id: @user.id).first
    else
      @recommendation = Recommendation.where(restaurant_id: restaurant_id, user_id: user_id).first
    end

    new_params = recommendation_params
    new_params["friends_thanking"] = recommendation_params["friends_thanking"] ? recommendation_params["friends_thanking"].map{|x| x.to_i} : []
    new_params["experts_thanking"] = recommendation_params["experts_thanking"] ? recommendation_params["experts_thanking"].map{|x| x.to_i} : []
    new_params["review"] = recommendation_params["review"] ? recommendation_params["review"] : "Je recommande !"

    reallocate_thanks_if_changes(new_params)

    @recommendation.update_attributes(new_params)

    # on renvoie le restaurant et l'activité
    restaurant_info = JSON(Nokogiri.HTML(open("http://www.needl.fr/api/v2/restaurants/#{@recommendation.restaurant_id}.json?user_email=#{@user.email}&user_token=#{@user.authentication_token}")))
    restaurant_info.each { |k, v| restaurant_info[k] = v.encode("iso-8859-1").force_encoding("utf-8") if v.class == String }

      render json: {
        restaurant: restaurant_info,
        activity: {user_id: @user.id, restaurant_id: @recommendation.restaurant_id, user_type: "me", notification_type: "recommendation", review: @recommendation.review, date: @recommendation.created_at, strengths: @recommendation.strengths, ambiences: @recommendation.ambiences, occasions: @recommendation.occasions, friends_thanking: @recommendation.friends_thanking, experts_thanking: @recommendation.experts_thanking}
      }

  end

  private

  def recommendation_params
    params.require(:recommendation).permit(:review, { strengths: [] }, { ambiences: [] }, { occasions: [] }, { friends_thanking: [] }, { experts_thanking: [] })
  end


  def tell_all_friends
    friends_id = @user.my_friends_ids
    if friends_id.length > 0
      friends_id.each do |friend_id|
        @friend = User.find(friend_id)
        @friend.send_new_friend_email(@user)
      end
    end

  end


  def notif_reco(users_already_thanked_ids)

    client = Parse.create(application_id: ENV['PARSE_APPLICATION_ID'], api_key: ENV['PARSE_API_KEY'])

    # s'il ne renvoie rien ca donne un tableau vide
    users_ids_not_to_send_again = users_already_thanked_ids != nil ? users_already_thanked_ids.map{|x| x.to_i} : []
    relevant_friends_ids = @user.my_friends_seing_me_ids - users_ids_not_to_send_again
    if relevant_friends_ids != []
     # envoyer à chaque friend que @user a fait une nouvelle reco du resto @restaurant
     data = { :alert => "#{@user.name} a recommande #{@restaurant.name}", :badge => 'Increment', :type => 'reco' }
     push = client.push(data)
     # push.type = "ios"
     query = client.query(Parse::Protocol::CLASS_INSTALLATION).value_in('user_id', relevant_friends_ids)
     push.where = query.where
     push.save
    end

  end

  def thank_friends(friends_to_thank_ids)

    client = Parse.create(application_id: ENV['PARSE_APPLICATION_ID'], api_key: ENV['PARSE_API_KEY'], master_key:ENV['PARSE_MASTER_KEY'])
    friends_to_notif_ids = []
    friends_to_mail_ids = []

    # pour chaque utilisateur on va regarder si il a activé les notis et s'il l'a fait on lui envoie une notif, s'il ne l'a pas fait on lui envoie un mail
    friends_to_thank_ids.each do |friend_id|
      info = client.query(Parse::Protocol::CLASS_INSTALLATION).eq('user_id', friend_id).get
      puts "-----------------------------------------------------------------------"
      puts "#{info.length}"
      if info.length > 0
        friends_to_notif_ids << friend_id
      else
        friends_to_mail_ids << friend_id
      end

      # on leur fait gagner à chacun un point d'expertise
      friend = User.find(friend_id)
      friend.score += 1
      friend.save

    end

    # on envoie les notifs aux bonnes personnes s'il y en a
    if friends_to_notif_ids.length > 0
      puts "---------------------------------------------------------------------------"
      puts "params : #{params}"
      puts "user: #{@user.name}"
      @user = User.find_by(authentication_token: params["user_token"])
      puts "user_new: #{@user.name}"
      data = { :alert => "#{@user.name} te remercie de lui avoir fait decouvrir #{@restaurant.name}. Tu gagnes 1 point d'expertise !", :badge => 'Increment', :type => 'thanks' }
      push = client.push(data)
      query = client.query(Parse::Protocol::CLASS_INSTALLATION).value_in('user_id', friends_to_notif_ids)
      push.where = query.where
      push.save
      # on track les envois
      friends_to_notif_ids.each do |friend_id|
        @tracker.track(@user.id, 'Thanks sent', { "user" => @user.name, "type" => "Notif",  "User Type" => "Friend" })
      end
    end

    # on envoie les mails aux bonnes personnes s'il y en a
    if friends_to_mail_ids.length > 0
      friends = User.find(friends_to_mail_ids)
      friends_infos = friends.map {|x| {name: x.name.split(" ")[0], email: x.email}}
      @user.send_thank_friends_email(friends_infos, @restaurant.id)
    end

  end

  def thank_experts(experts_to_thank_ids)

    experts_to_thank_ids.each do |expert_id|
      # on leur fait gagner à chacun un point d'expertise
      expert = User.find(expert_id)
      expert.public_score += 1
      expert.save
      @tracker.track(@user.id, 'Thanks sent', { "user" => @user.name, "type" => "Nothing",  "User Type" => "Expert"})
    end
  end

  def reallocate_thanks_if_changes(new_params)

    friends_previously_thanked = @recommendation.friends_thanking.map{|x| x.to_i}
    experts_previously_thanked = @recommendation.experts_thanking.map{|x| x.to_i}
    friends_newly_thanked      = new_params["friends_thanking"].map{|x| x.to_i}
    experts_newly_thanked      = new_params["experts_thanking"].map{|x| x.to_i}
    puts "----------------------------------------------------------------------------"
    puts "friends_previously_thanked: #{friends_previously_thanked}"
    puts "friends_newly_thanked: #{friends_newly_thanked}"

    # On check ceux qui auraient été rajoutés avec l’update
    new_minus_old_friends      = friends_newly_thanked - friends_previously_thanked
    # On check ceux qui auraient été enlevés avec l’update
    old_minus_new_friends      = friends_previously_thanked - friends_newly_thanked


    old_minus_new_experts      = experts_previously_thanked - experts_newly_thanked
    new_minus_old_experts      = experts_newly_thanked - experts_previously_thanked

    if new_minus_old_friends.length > 0
      thank_friends(new_minus_old_friends)
    end

    if old_minus_new_friends.length > 0
      unthank_friends(new_minus_old_friends)
    end

    if new_minus_old_experts.length > 0
      thank_experts(new_minus_old_experts)
    end

    if old_minus_new_experts.length > 0
      unthank_experts(new_minus_old_experts)
    end

  end

  def unthank_friends(friends_to_unthank_ids)

    friends_to_unthank_ids.each do |friend_id|
      # on leur fait perdre à chacun un point d'expertise
      friend = User.find(friend_id)
      friend.score -= 1
      friend.save
      @tracker.track(@user.id, 'Unthanks', { "user" => @user.name, "User Type" => "Friend"})
    end

  end

  def unthank_experts(experts_to_unthank_ids)

    experts_to_unthank_ids.each do |expert_id|
      # on leur fait perdre à chacun un point d'expertise
      expert = User.find(expert_id)
      expert.public_score -= 1
      expert.save
      @tracker.track(@user.id, 'Unthanks', { "user" => @user.name, "User Type" => "Expert"})
    end

  end

  # def read_all_notification
  #   load_activities
  #   @activities.each do |activity|
  #     activity.read = true
  #     activity.save
  #   end
  # end

end