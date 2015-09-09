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
        render(:json => {notice: "Restaurant déjà sur ta wishlist"}, :status => 409, :layout => false)
      else
        @wish = Wish.create(user_id: @user.id, restaurant_id: params["restaurant_id"].to_i)
        redirect_to api_restaurant_path(params["restaurant_id"].to_i, :user_email => params["user_email"], :user_token => params["user_token"], :notice => "Restaurant ajouté à ta wishlist")
      end
    end

    def destroy
      wish = Wish.where(user_id: @user.id, restaurant_id: params["restaurant_id"].to_i).first
      if PublicActivity::Activity.where(trackable_type: "Wish").find_by(trackable_id: wish.id).length > 0
        activity = PublicActivity::Activity.where(trackable_type: "Wish").find_by(trackable_id: wish.id)
        activity.destroy
      end
      wish.destroy
      redirect_to api_restaurant_path(params["restaurant_id"].to_i, :user_email => params["user_email"], :user_token => params["user_token"], :notice => "Le restaurant a bien été retiré de la liste de vos envies")
    end

    private

    # def wish_params
    #   params.require(:wish).permit(:user_id, :restaurant_id)
    # end

    # je ne passe pas par les strong params, voir si c'est un problème

  end
end