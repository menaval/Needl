module Api
  class UsersController < ApplicationController
    # acts_as_token_authentication_handler_for User
    skip_before_action :verify_authenticity_token
    skip_before_filter :authenticate_user!

    def show
      # @user = User.find(params["id"].to_i)
      @user = User.find_by(authentication_token: params["user_token"])
      @restaurants = Restaurant.joins(:recommendations).where(recommendations: { user_id: @user.id })
    end

  end
end