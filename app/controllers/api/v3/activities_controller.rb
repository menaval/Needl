class Api::V3::ActivitiesController < ApplicationController
  acts_as_token_authentication_handler_for User
  skip_before_action :verify_authenticity_token
  skip_before_filter :authenticate_user!

  def index

    @user = User.find_by(authentication_token: params["user_token"])
    my_experts_ids = @user.followings.pluck(:id)
    my_visible_friends_ids = @user.my_visible_friends_ids
    @activities = []

    Recommendation.where(user_id: my_visible_friends_ids).each do |reco|
      @activities << {user_id: reco.user_id, restaurant_id: reco.restaurant_id, date: reco.created_at, url: reco.url ? reco.url : "", user_type: "friend" , notification_type: "recommendation", strengths: reco.strengths, ambiences: reco.ambiences, occasions: reco.occasions, review: reco.review, friends_thanking: reco.friends_thanking, experts_thanking: reco.experts_thanking}
    end

    Recommendation.where(user_id: @user.id).each do |reco|
      @activities << {user_id: reco.user_id, restaurant_id: reco.restaurant_id, date: reco.created_at, url: reco.url ? reco.url : "", user_type: "me" , notification_type: "recommendation", strengths: reco.strengths, ambiences: reco.ambiences, occasions: reco.occasions, review: reco.review, friends_thanking: reco.friends_thanking, experts_thanking: reco.experts_thanking}
    end

    Recommendation.where(user_id: my_experts_ids, public: true).each do |reco|
      @activities << {user_id: reco.user_id, restaurant_id: reco.restaurant_id, date: reco.created_at, url: reco.url ? reco.url : "", user_type: "following" , notification_type: "recommendation", strengths: reco.strengths, ambiences: reco.ambiences, occasions: reco.occasions, review: reco.review, friends_thanking: reco.friends_thanking, experts_thanking: reco.experts_thanking}
    end

    Wish.where(user_id: my_visible_friends_ids).each do |wish|
      @activities << {user_id: wish.user_id, restaurant_id: wish.restaurant_id, date: wish.created_at, user_type: "friend" , notification_type: "wish", review: "Sur ma wishlist", influencer_id: wish.influencer_id}
    end

    Wish.where(user_id: @user.id).each do |wish|
      @activities << {user_id: wish.user_id, restaurant_id: wish.restaurant_id, date: wish.created_at, user_type: "me" , notification_type: "wish", review: "Sur ma wishlist", influencer_id: wish.influencer_id}
    end
  end

  def show
    @user = User.find_by(authentication_token: params["user_token"])
    friend_id = params["id"]
    @activities = []

    Recommendation.where(user_id: friend_id).each do |reco|
      @activities << {user_id: reco.user_id, restaurant_id: reco.restaurant_id, date: reco.created_at, url: reco.url ? reco.url : "", user_type: friend_id == @user.id ? "me" : "friend" , notification_type: "recommendation", strengths: reco.strengths, ambiences: reco.ambiences, occasions: reco.occasions, review: reco.review, friends_thanking: reco.friends_thanking, experts_thanking: reco.experts_thanking}
    end

    Wish.where(user_id: friend_id).each do |wish|
      @activities << {user_id: wish.user_id, restaurant_id: wish.restaurant_id, date: wish.created_at, user_type: friend_id == @user.id ? "me" : "friend" , notification_type: "wish", review: "Sur ma wishlist"}
    end

  end

  def marked_as_read
    user = User.find_by(authentication_token: params["user_token"])
    date = Time.now
    user.notifications_read_date = date
    user.save

    render json: {message: "sucess", notification_date: date}
  end

end