module Api
  class RecommendationsController < ApplicationController
    acts_as_token_authentication_handler_for User
    skip_before_action :verify_authenticity_token
    skip_before_filter :authenticate_user!
    respond_to :json


    def index
      user = User.find_by(authentication_token: params["user_token"])
      @api_activities = PublicActivity::Activity.where(owner_id: user.my_friends_ids, owner_type: 'User').order('created_at DESC').limit(20)
    end

    def new
      @user = User.find_by(authentication_token: params["user_token"])
      @recommendation = Recommendation.new
      if params["restaurant_id"]
        create
      end
    end

    def create
      respond_with Recommendation.create(recommendation_params)
      # ne le lit pas au format json mais html ce qui ne marche donc pas
    end

    private

    def recommendation_params
      params.require(:recommendation).permit(:review, { strengths: [] }, { ambiences: [] }, { price_ranges: [] })
    end

  end
end
