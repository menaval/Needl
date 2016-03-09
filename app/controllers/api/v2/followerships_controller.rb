class Api::V2::FollowershipsController < ApplicationController
  acts_as_token_authentication_handler_for User
  skip_before_action :verify_authenticity_token
  skip_before_filter :authenticate_user!

  def index
    @user = User.find_by(authentication_token: params["user_token"])
    my_followerships = Followership.where(follower_id: @user.id)
    my_experts_ids = my_followerships.pluck(:following_id)
    @my_experts = User.where(id: my_experts_ids)

    @experts_recommendations = {}
    @experts_public_recommendations = {}
    Recommendation.where(user_id: my_experts_ids).each do |recommendation|
        @experts_recommendations[recommendation.user_id] ||= []
        @experts_recommendations[recommendation.user_id] << recommendation.restaurant_id
      if recommendation.public == true
        @experts_public_recommendations[recommendation.user_id] ||= []
        @experts_public_recommendations[recommendation.user_id] << recommendation.restaurant_id
      end
    end

    @followings_ids = {}
    my_followerships.each do |followership|
      @followings_ids[followership.following_id] = followership.id
    end

    @experts_wishes = {}
    Wish.where(user_id: my_experts_ids).each do |wish|
      @experts_wishes[wish.user_id] ||= []
      @experts_wishes[wish.user_id] << wish.restaurant_id
    end

    @experts_followers = {}
    Followership.where(following_id: my_experts_ids).each do |followership|
      @experts_followers[followership.following_id] ||= []
      @experts_followers[followership.following_id] << followership.follower_id
    end

    @experts_followings = {}
    Followership.where(follower_id: my_experts_ids).each do |followership|
      @experts_followers[followership.follower_id] ||= []
      @experts_followers[followership.follower_id] << followership.following_id
    end

  end

  def create
   user = User.find_by(authentication_token: params["user_token"])
   following = User.find(params["following_id"].to_i)
   Followership.create(follower_id: user.id, following_id: following.id)
   @tracker.track(user.id, 'Followership Created', { "follower" => user.name, "following" => following.name})
   render json: {message: "success"}
   # renvoyer restaurants, activities
  end

  def destroy
    @user = User.find_by(authentication_token: params["user_token"])
    followership = Followership.find(params["id"].to_i)
    following = followership.following

    # Supprimer tous les points donnés par l'utilisateur
    recos_from_expert = Recommendation.find_by_sql("SELECT * FROM recommendations WHERE user_id = #{@user.id} AND experts_thanking @> '{#{following.id}}'")
    recos_from_expert.each do |reco|
      new_experts_thanking = reco.experts_thanking - [following.id]
      reco.update_attributes(experts_thanking: new_experts_thanking)
      unthank_experts([following.id])
    end

    followership.destroy
    @tracker.track(user.id, 'Followership Destroyed', { "user" => @user.name, "following" => following.name})
    render json: {message: "success"}
    # renvoyer restaurants
  end

end