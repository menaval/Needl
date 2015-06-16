module Api
  class FriendshipsController < ApplicationController
    acts_as_token_authentication_handler_for User
    skip_before_action :verify_authenticity_token
    skip_before_filter :authenticate_user!

    def index
      @user = User.find_by(authentication_token: params["user_token"])
      @friends = User.where(id: @user.my_friends_ids)
      @requests = User.where(id: current_user.my_requests_received_ids)
    end

    def new

    end

  end
end