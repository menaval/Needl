module Api
  class RegistrationsController < ApplicationController
    # acts_as_token_authentication_handler_for User
    skip_before_action :verify_authenticity_token
    skip_before_filter :authenticate_user!

    def edit
      @user = User.find_by(authentication_token: params["user_token"])
      if params['email']
        update
      end
    end

    def update
      @user.update_attributes(name: params['name'], email: params['email'])
      redirect_to edit_api_registration_path
    end
  end
end