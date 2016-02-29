module Api
  class SessionsController < ApplicationController
    # acts_as_token_authentication_handler_for User
    skip_before_action :verify_authenticity_token
    skip_before_filter :authenticate_user!

    def create
      resource = warden.authenticate!(:scope => :user)
      sign_in(:user, resource)
      redirect_to api_restaurants_path(:user_email => resource.email, :user_token => resource.authentication_token)

      # la requete postman
      # http://localhost:3000/api/sessions.json?utf8=✓&authenticity_token=jtZs5ZKD4jP3RpegLhGGj86q6EBnFHaHoSAjCBisIVc6iPAdTr0Xcwpj5Da08H64p74KeuefxHB1J9UXapgYew==&user[email]=yolo4@gmail.co&user[password]=12345678&commit=Sign in
    end

  end
end