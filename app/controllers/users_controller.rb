class UsersController < ApplicationController

  def verification_code
    code = params[:verification][:code]
    if code == "friend" || code == "lewagon"
      redirect_to new_recommendation_path, notice: "Partages ta première reco avant de découvrir celles de tes amis !"
    else
      redirect_to access_users_path, notice: "Le code n'est pas valide"
    end
  end

  def my_restaurant
    @restaurants = current_user.restaurants
  end

end
