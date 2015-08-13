module Api
  class WishesController < ApplicationController
    acts_as_token_authentication_handler_for User
    skip_before_action :verify_authenticity_token
    skip_before_filter :authenticate_user!


    def index
      @user = User.find_by(authentication_token: params["user_token"])
      if params['destroy']
        destroy
      else
        create
      end
    end

    def create
      if Wish.where(restaurant_id:params["restaurant_id"].to_i, user_id: @user.id).any?
        redirect_to api_restaurants_path(:user_email => params["user_email"], :user_token => params["user_token"])
      else
        @wish = Wish.create(user_id: @user.id, restaurant_id: params["restaurant_id"].to_i)
        redirect_to api_restaurant_path(params["restaurant_id"].to_i, :user_email => params["user_email"], :user_token => params["user_token"])
      end
    end

    def destroy
      wish = Wish.where(user_id: @user.id, restaurant_id: params["restaurant_id"].to_i).first
      wish.destroy
      redirect_to api_restaurant_path(params["restaurant_id"].to_i, :user_email => params["user_email"], :user_token => params["user_token"])
    end

    private

    # def wish_params
    #   params.require(:wish).permit(:user_id, :restaurant_id)
    # end

    # je ne passe pas par les strong params, voir si c'est un problème

  end
end