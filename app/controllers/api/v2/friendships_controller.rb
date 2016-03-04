class Api::V2::FriendshipsController < ApplicationController
  acts_as_token_authentication_handler_for User
  skip_before_action :verify_authenticity_token
  skip_before_filter :authenticate_user!
  respond_to :json

  def index
    @user = User.find_by(authentication_token: params["user_token"])
    my_friends_ids = @user.my_friends_ids
    @friends = User.where(id: my_friends_ids).order(:name)
    @requests = User.where(id: @user.my_requests_received_ids)
    t = Friendship.arel_table
    friendships = Friendship.where(t[:sender_id].eq_any(my_friends_ids).and(t[:receiver_id].eq(@user.id)).or(t[:sender_id].eq(@user.id).and(t[:receiver_id].eq_any(my_friends_ids))))

    @invisibility = {}
    friendships.each do |friendship|
      if friendship.sender_id == @user.id
        @invisibility[friendship.receiver_id] = friendship.receiver_invisible
      else
        @invisibility[friendship.sender_id] = friendship.sender_invisible
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

    # chercher une méthode 'automatique'
    if params["accepted"] == "false"
      create
    elsif params["accepted"] == "true"
      answer_yes
    elsif params["invisible"]
      invisible
    elsif params["not_interested"]
      @tracker.track(@user.id, 'ignore_friend', { "user" => @user.name })
      not_interested
    end
  end

  def new
    @user = User.find_by(authentication_token: params["user_token"])
    @friendship = Friendship.new
    @not_interested_relation = NotInterestedRelation.new
    @new_potential_friends = @user.user_friends - User.where(id: @user.my_friends_ids) - User.where(id: @user.my_requests_sent_ids) - User.where(id: @user.my_requests_received_ids) - User.where(id: @user.refused_relations_ids) - [@user]
  end

  private

  # A supprimer

  def create
    @friend_id = params["friend_id"].to_i
    # en attendant de détruire complètement cette étape, on met accepted à true
    @friendship = Friendship.new(sender_id: @user.id, receiver_id: @friend_id, accepted: true)
    @friendship.save
    @tracker.track(@user.id, 'add_friend', { "user" => @user.name })
    notif_friendship("invited")
    render json: {message: "sucess"}
    # ex: http://localhost:3000/api/friendships/new?friendship[sender_id]=40&friendship[receiver_id]=42&friendship[accepted]=false

  end

  # A supprimer

  def answer_yes
    @friend_id = params["friend_id"].to_i
    friendship = Friendship.where(sender_id: @friend_id, receiver_id: @user.id).first
    friendship.update_attribute(:accepted, true)
    @tracker.track(@user.id, 'accept_friend', { "user" => @user.name })
    notif_friendship("accepted")
    render json: {message: "sucess"}
  end

  def destroy

    @user = User.find_by(authentication_token: params["user_token"])
    friend_id = params["id"].to_i
    # pour voir dans quelle sens s'est faite la relation sans avoir à le préciser dans l'url
    if Friendship.where(sender_id: friend_id, receiver_id: @user.id).first
      friendship = Friendship.where(sender_id: friend_id, receiver_id: @user.id).first
      NotInterestedRelation.create(member_one_id: friend_id, member_two_id: @user.id)
    else
      friendship = Friendship.where(sender_id: @user.id, receiver_id: friend_id).first
      NotInterestedRelation.create(member_one_id: @user.id, member_two_id: friend_id)
    end


    # Supprimer tous les points donnés par le friend
    @recos = Recommendation.find_by_sql("SELECT * FROM recommendations WHERE recommendations.user_id = #{friend_id} WHERE recommendations.friends_thanking @> '{#{@user.id}}'")
    @recos.each do |reco|
      new_friends_thanking = reco.friends_thanking - [@user.id]
      reco.update_attributes(friends_thanking: new_friends_thanking)
      unthank_friend([@user.id])
    end

    # Supprimer tous les points donnés par le user
    @recos = Recommendation.find_by_sql("SELECT * FROM recommendations WHERE recommendations.user_id = #{@user.id} WHERE recommendations.friends_thanking @> '{#{friend_id}}'")
    @recos.each do |reco|
      new_friends_thanking = reco.friends_thanking - [friend_id]
      reco.update_attributes(friends_thanking: new_friends_thanking)
      unthank_friend([friend_id])
    end

    friendship.destroy
    @tracker.track(@user.id, 'refuse_or_delete_friend', { "user" => @user.name })
    render json: {message: "sucess"}
    # gérer la redirection suivant un delete ou un ignore
  end

  def invisible
    invisible = params["invisible"]
    if Friendship.where(sender_id: params["friend_id"].to_i, receiver_id: @user.id).first
      friendship = Friendship.where(sender_id: params["friend_id"].to_i, receiver_id: @user.id).first
      friendship.update_attribute(:sender_invisible, invisible)
    else
      friendship = Friendship.where(sender_id: @user.id, receiver_id: params["friend_id"].to_i).first
      friendship.update_attribute(:receiver_invisible, invisible)
    end
    if invisible == true
      @tracker.track(@user.id, 'hide_friend', { "user" => @user.name })
    else
      @tracker.track(@user.id, 'unhide_friend', { "user" => @user.name })
    end
    render json: {message: "sucess"}
  end

  #  A supprimer

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

  def not_interested
    NotInterestedRelation.create(member_one_id: @user.id, member_two_id: params["friend_id"])
    render json: {message: "sucess"}
  end

  # def friendship_params
  #   params.require(:friendship).permit(:sender_id, :receiver_id, :accepted)
  # end

  # je ne passe pas par les strong params à voir


end