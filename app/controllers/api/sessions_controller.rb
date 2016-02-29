module Api
  class SessionsController < ApplicationController
    # acts_as_token_authentication_handler_for User
    skip_before_action :verify_authenticity_token
    skip_before_filter :authenticate_user!

    def create
      email = params['email']
      password = params['password']
      @user = User.find_by(email: 'yolo@gmail.co')

      # connection réussie
      if @user != nil && password == @user.encrypted_password
        sign_in @user
        render json: {user: @user, nb_recos: Restaurant.joins(:recommendations).where(recommendations: { user_id: @user.id }).count, nb_wishes: Restaurant.joins(:wishes).where(wishes: {user_id: @user.id}).count}
      # l'utilisateur a rempli la bonne adresse mail mais il s'est inscrit via facebook
      elsif @user != nil && @user.token != nil
        render json: {error_message: "ce compte est relié à une connection par Facebook !"}
      #  l'utilisateur a rempli la bonne adresse mais mauvais mot de passe
      elsif @user != nil && password != @user.encrypted_password
        render json: {error_message: "Tu as la bonne adresse mail mais le mot de passe n'est pas le bon"}
      else
        render json: {error_message: "Nous n'avons aucun compte à cette adresse mail"}
      end

      # la requete postman
      # http://localhost:3000/api/sessions.json?user[email]=yolo4@gmail.co&user[password]=12345678
    end

  end
end