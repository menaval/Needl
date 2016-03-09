class Api::V2::FriendshipsController < ApplicationController
  acts_as_token_authentication_handler_for User
  skip_before_action :verify_authenticity_token
  skip_before_filter :authenticate_user!
  respond_to :json

  def index
    @user = User.find_by(authentication_token: params["user_token"])
    my_friends_ids = @user.my_friends_ids
    @friends = User.where(id: my_friends_ids).order(:name)
    requests_received = Friendship.where(receiver_id: @user.id, accepted: false).where.not(sender_id: @user.refuseds)
    @requests_received_users = User.where(id: @user.my_requests_received_ids - @user.refuseds)
    requests_sent = Friendship.where(sender_id: @user.id, accepted: false).where.not(receiver_id: @user.refusers)
    @requests_sent_users = User.where(id: @user.my_requests_sent_ids - @user.refusers)
    t = Friendship.arel_table
    friendships = []
    # pour éviter les bugs si l'utilisateur n'a pas d'amis
    if requests_received + requests_sent != []
      friendships = Friendship.where(t[:sender_id].eq_any(my_friends_ids).and(t[:receiver_id].eq(@user.id)).or(t[:sender_id].eq(@user.id).and(t[:receiver_id].eq_any(my_friends_ids))))
    end

    @requests_received_id = {}
    requests_received.each do |request|
      @requests_received_id[request.sender_id] = request.id
    end

    @requests_sent_id = {}
    requests_sent.each do |request|
      @requests_sent_id[request.receiver_id] = request.id
    end

    @infos = {}
    friendships.each do |friendship|
      if friendship.sender_id == @user.id
        @infos[friendship.receiver_id] = {friendship_id: friendship.id, invisibility: friendship.receiver_invisible}
      else
        @infos[friendship.sender_id] = {friendship_id: friendship.id, invisibility: friendship.sender_invisible}
      end
    end

    recommendations_from_friends  = Recommendation.where(user_id: my_friends_ids)
    wishes_from_friends          = Wish.where(user_id: my_friends_ids)

    @friends_recommendations = {}
    recommendations_from_friends.each do |recommendation|
      @friends_recommendations[recommendation.user_id] ||= []
      @friends_recommendations[recommendation.user_id] << recommendation.restaurant_id
    end

    @friends_wishes = {}
    wishes_from_friends.each do |wish|
      @friends_wishes[wish.user_id] ||= []
      @friends_wishes[wish.user_id] << wish.restaurant_id
    end

    @all_followers = {}
    Followership.where(following_id: my_friends_ids).each do |followership|
      @all_followers[followership.following_id] ||= []
      @all_followers[followership.following_id] << followership.follower_id
    end

    @all_followings = {}
    Followership.where(follower_id: my_friends_ids).each do |followership|
      @all_followers[followership.follower_id] ||= []
      @all_followers[followership.follower_id] << followership.following_id
    end

    @all_public_recos = {}
    Recommendation.where(user_id: my_friends_ids, public: true).each do |reco|
      @all_public_recos[reco.user_id] ||= []
      @all_public_recos[reco.user_id] << reco.restaurant_id
    end

    split_friends_by_categories

  end

  def destroy
    @user = User.find_by(authentication_token: params["user_token"])
    friendship = Friendship.find(params["id"])
    friend_id = friendship.sender_id == @user.id ? friendship.receiver_id : friendship.sender_id
    NotInterestedRelation.create(refuser_id: @user.id, refused_id: friend_id)

    # Supprimer tous les points donnés par le friend
    recos_from_friend = Recommendation.find_by_sql("SELECT * FROM recommendations WHERE user_id = #{friend_id} AND friends_thanking @> '{#{@user.id}}'")
    recos_from_friend.each do |reco|
      new_friends_thanking = reco.friends_thanking - [@user.id]
      reco.update_attributes(friends_thanking: new_friends_thanking)
      unthank_friends([@user.id])
    end

    # Supprimer tous les points donnés par le user
    recos_from_me = Recommendation.find_by_sql("SELECT * FROM recommendations WHERE user_id = #{@user.id} AND friends_thanking @> '{#{friend_id}}'")
    recos_from_me.each do |reco|
      new_friends_thanking = reco.friends_thanking - [friend_id]
      reco.update_attributes(friends_thanking: new_friends_thanking)
      unthank_friends([friend_id])
    end

    friendship.destroy
    @tracker.track(@user.id, 'delete_friend', { "user" => @user.name })
    redirect_to user_updated_api_v2_restaurants_path(:user_updated => friend_id, :user_email => params["user_email"], :user_token => params["user_token"])
  end

  def ask
    @user = User.find_by(authentication_token: params["user_token"])
    @friend_id = params["friend_id"].to_i
    friend = User.find(@friend_id)
    @friendship = Friendship.new(sender_id: @user.id, receiver_id: @friend_id, accepted: false)
    @friendship.save
    @tracker.track(@user.id, 'ask_friend', { "user" => @user.name })
    notif_friendship("invited")
    render json: {
      request: {friendship_id: @friendship.id, name: friend.name, picture: friend.picture, id: friend.id}
    }
  end

  def accept
    @user = User.find_by(authentication_token: params["user_token"])
    friendship = Friendship.find(params["id"])
    @friend_id = friendship.sender_id
    friendship.update_attribute(:accepted, true)
    @tracker.track(@user.id, 'accept_friend', { "user" => @user.name })
    notif_friendship("accepted")

    # on renvoie le profil, ses activités et les restaurants updatés
    user_info = JSON(Nokogiri.HTML(open("http://www.needl.fr/api/v2/users/#{@friend_id}.json?user_email=#{@user.email}&user_token=#{@user.authentication_token}")))
    user_info.each { |k, v| user_info[k] = v.encode("iso-8859-1").force_encoding("utf-8") if v.class == String }

    activities_from_user_info = JSON(Nokogiri.HTML(open("http://www.needl.fr/api/v2/activities/#{@friend_id}.json?user_email=#{@user.email}&user_token=#{@user.authentication_token}")))
    activities_from_user_info.each { |k, v| activities_from_user_info[k] = v.encode("iso-8859-1").force_encoding("utf-8") if v.class == String }

    user_restaurants_info = JSON(Nokogiri.HTML(open("http://www.needl.fr/api/v2/restaurants/user_updated.json?user_updated=#{@friend_id}&user_email=#{@user.email}&user_token=#{@user.authentication_token}")))
    user_restaurants_info.each { |k, v| user_restaurants_info[k] = v.encode("iso-8859-1").force_encoding("utf-8") if v.class == String }


      render json: {
        friend: user_info,
        activities: activities_from_user_info,
        restaurants: user_restaurants_info
      }
  end

  def refuse
    user = User.find_by(authentication_token: params["user_token"])
    friendship = Friendship.find(params["id"])
    @tracker.track(user.id, 'refuse_friend', { "user" => user.name })
    NotInterestedRelation.create(refuser_id: user.id, refused_id: friendship.sender_id)
    render json: {message: "success"}
  end


  def make_invisible
    user = User.find_by(authentication_token: params["user_token"])
    friendship = Friendship.find(params["id"])
    friend_id = 0
    if friendship.sender_id == user.id
      friendship.update_attribute(:receiver_invisible, true)
      friend_id = friendship.receiver_id
    else
      friendship.update_attribute(:sender_invisible, true)
      friend_id = friendship.sender_id
    end
    @tracker.track(user.id, 'hide_friend', { "user" => user.name })

    # renvoyer restaurants
    redirect_to user_updated_api_v2_restaurants_path(:user_updated => friend_id, :user_email => params["user_email"], :user_token => params["user_token"])
  end

  def make_visible
    user = User.find_by(authentication_token: params["user_token"])
    friendship = Friendship.find(params["id"])
    friend_id = 0
    if friendship.sender_id == user.id
      friendship.update_attribute(:receiver_invisible, false)
      friend_id = friendship.receiver_id
    else
      friendship.update_attribute(:sender_invisible, false)
      friend_id = friendship.sender_id
    end
    @tracker.track(user.id, 'unhide_friend', { "user" => user.name })

    # renvoyer activities, restaurants
    activities_from_user_info = JSON(Nokogiri.HTML(open("http://www.needl.fr/api/v2/activities/#{friend_id}.json?user_email=#{user.email}&user_token=#{user.authentication_token}")))
    activities_from_user_info.each { |k, v| activities_from_user_info[k] = v.encode("iso-8859-1").force_encoding("utf-8") if v.class == String }

    user_restaurants_info = JSON(Nokogiri.HTML(open("http://www.needl.fr/api/v2/restaurants/user_updated.json?user_updated=#{friend_id}&user_email=#{user.email}&user_token=#{user.authentication_token}")))
    user_restaurants_info.each { |k, v| user_restaurants_info[k] = v.encode("iso-8859-1").force_encoding("utf-8") if v.class == String }

    render json: {
      activities: activities_from_user_info,
      restaurants: user_restaurants_info
    }
  end

  private

  def notif_friendship(status)

    client = Parse.create(application_id: ENV['PARSE_APPLICATION_ID'], api_key: ENV['PARSE_API_KEY'])
    # status: nouvelle demande ou accepté ?
    if status == "accepted"
      # envoyer à @friend qu'il a été accepté
      data = { :alert => "#{@user.name} a accepte votre invitation", :badge => 'Increment', :type => 'friend' }
      push = client.push(data)
      # push.type = "ios"
      query = client.query(Parse::Protocol::CLASS_INSTALLATION).eq('user_id', @friend_id)
      push.where = query.where
      push.save
    else
      # envoyer à @friend qu'on l'a invité
      data = { :alert => "#{@user.name} vous invite a decouvrir ses restaurants", :badge => 'Increment', :type => 'friend' }
      push = client.push(data)
      # push.type = "ios"
      query = client.query(Parse::Protocol::CLASS_INSTALLATION).eq('user_id', @friend_id)
      push.where = query.where
      push.save
    end

  end



  # def friendship_params
  #   params.require(:friendship).permit(:sender_id, :receiver_id, :accepted)
  # end

  # je ne passe pas par les strong params à voir


end