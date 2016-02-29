module Api
  class SessionsController < ApplicationController
    # acts_as_token_authentication_handler_for User
    skip_before_action :verify_authenticity_token
    skip_before_filter :authenticate_user!

    def create
      resource = warden.authenticate!(:scope => :user)
      sign_in(:user, resource)
      puts "#{resource.name}"
      puts "#{resource.email}"
      render json: {user: resource, nb_recos: Restaurant.joins(:recommendations).where(recommendations: { user_id: resource.id }).count, nb_wishes: Restaurant.joins(:wishes).where(wishes: {user_id: resource.id}).count}

      # la requete postman
      # http://localhost:3000/api/sessions.json?user[email]=yolo4@gmail.co&user[password]=12345678
    end

  end
end