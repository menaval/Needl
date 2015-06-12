module Api
  class RecommendationsController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_before_filter :authenticate_user!

    def index
      user = User.find_by(authentication_token: params["user_token"])
      @api_activities = PublicActivity::Activity.where(owner_id: user.my_friends_ids, owner_type: 'User').order('created_at DESC').limit(20)
    end

  end
end
