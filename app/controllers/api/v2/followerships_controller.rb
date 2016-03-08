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

end