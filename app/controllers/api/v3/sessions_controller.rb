class Api::V3::SessionsController < ApplicationController
  # acts_as_token_authentication_handler_for User
  skip_before_action :verify_authenticity_token
  skip_before_filter :authenticate_user!

  def create
    if params['from'] == 'wish'
      email = params['user']['email']
      password = params['user']['password']
    else 
      email = params['email']
      password = params['password']
    end

    @user = User.find_by(email: email)

    # connection réussie
    if @user != nil && @user.valid_password?(password) == true
      sign_in @user

      if params['from'] == 'wish'
        restaurant_id = params['restaurant_id'].to_i

        if Wish.where(user_id: @user.id, restaurant_id: restaurant_id).length > 0
          # already wishlisted
          redirect_to wish_failed_subscribers_path(message: 'already_wishlisted')
        elsif Recommendation.where(user_id: @user.id, restaurant_id: restaurant_id).length > 0
          # already recommended
          redirect_to wish_failed_subscribers_path(message: 'already_recommended')
        else            
          Wish.create(user_id: @user.id, restaurant_id: restaurant_id)
          redirect_to wish_success_subscribers_path
        end
      else
        render json: {user: @user, nb_recos: Restaurant.joins(:recommendations).where(recommendations: { user_id: @user.id }).count, nb_wishes: Restaurant.joins(:wishes).where(wishes: {user_id: @user.id}).count}
      end
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