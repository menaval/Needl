module Api
  class UsersController < ApplicationController
    # acts_as_token_authentication_handler_for User
    skip_before_action :verify_authenticity_token
    skip_before_filter :authenticate_user!

    def show
      @user = User.find(params["id"].to_i)
      # http://localhost:3000/api/users/40.json?user_email=valentin.menard@essec.edu&user_token=6Y-zoSafp5ynxURyFkMq
      # @user = User.find_by(authentication_token: params["user_token"])
      @restaurants = @user.my_restaurants
    end

  end
end