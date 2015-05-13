class UsersController < ApplicationController

  def verification_code
    code = params[:verification][:code]
    if code == "friend" || code == "family" || code == "lewagon"
      redirect_to new_recommendation_path, notice: "Partages ta première recommandation !"
    else
      redirect_to access_users_path, notice: "Le code n'est pas valide"
    end
  end

  def my_restaurant
    @restaurants = current_user.restaurants
  end

end
