class Api::V2::FollowershipsController < ApplicationController
  acts_as_token_authentication_handler_for User
  skip_before_action :verify_authenticity_token
  skip_before_filter :authenticate_user!

  def index
    @user = User.find_by(authentication_token: params["user_token"])
    @experts = @user.followings
    my_experts_ids = @user.followings.length != 0 ? @user.followings.pluck(:id) : []

    recommendations_from_experts  = Recommendation.where(user_id: my_experts_ids)
    @experts_recommendations = {}
    recommendations_from_experts.each do |recommendation|
      @experts_recommendations[recommendation.user_id] ||= []
      @experts_recommendations[recommendation.user_id] << recommendation.restaurant_id
    end

    followers_for_experts = Followership.where(following_id: my_experts_ids)
    @experts_followers = {}
    followers_for_experts.each do |followership|
      @experts_followers[followership.following_id] ||= []
      @experts_followers[followership.following_id] << followership.follower_id
    end
  end

end