class Api::V2::SessionsController < ApplicationController
  # acts_as_token_authentication_handler_for User
  skip_before_action :verify_authenticity_token
  skip_before_filter :authenticate_user!

  def create
    email = params['email']
    password = params['password']
    @user = User.find_by(email: email)

    # connection réussie
    if @user != nil && @user.valid_password?(password) == true
      sign_in @user
      render json: {user: @user, nb_recos: Restaurant.joins(:recommendations).where(recommendations: { user_id: @user.id }).count, nb_wishes: Restaurant.joins(:wishes).where(wishes: {user_id: @user.id}).count}
    # l'utilisateur a rempli la bonne adresse mail mais il s'est inscrit via facebook
    elsif @user != nil && @user.provider == "facebook"
      render(json: {error_message: "facebook_account"}, status: 401)
    #  l'utilisateur a rempli la bonne adresse mais mauvais mot de passe
    elsif @user != nil && @user.valid_password?(password) == false
      render(json: {error_message: "wrong_password"}, status: 401)
    else
      render(json: {error_message: "wrong_email"}, status: 401)
    end

    # la requete postman
    # http://localhost:3000/api/sessions.json?user[email]=yolo4@gmail.co&user[password]=12345678
  end

  def update_infos
    @user = User.find_by(authentication_token: params["user_token"])
    render json: {user: @user, nb_recos: Restaurant.joins(:recommendations).where(recommendations: { user_id: @user.id }).count, nb_wishes: Restaurant.joins(:wishes).where(wishes: {user_id: @user.id}).count}
  end
end