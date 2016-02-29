module Api
  class SessionsController < ApplicationController
    # acts_as_token_authentication_handler_for User
    skip_before_action :verify_authenticity_token
    skip_before_filter :authenticate_user!

    def create
      resource = warden.authenticate!(:scope => :user)
      sign_in(:user, resource)
      render json: {user: @user, nb_recos: Restaurant.joins(:recommendations).where(recommendations: { user_id: @user.id }).count, nb_wishes: Restaurant.joins(:wishes).where(wishes: {user_id: @user.id}).count}

      # la requete postman
      # http://localhost:3000/api/sessions.json?utf8=✓&authenticity_token=jtZs5ZKD4jP3RpegLhGGj86q6EBnFHaHoSAjCBisIVc6iPAdTr0Xcwpj5Da08H64p74KeuefxHB1J9UXapgYew==&user[email]=yolo4@gmail.co&user[password]=12345678&commit=Sign in
    end

  end
end