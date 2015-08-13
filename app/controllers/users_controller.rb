class UsersController < ApplicationController

  def show
    @user = User.find(params[:id])
  end


  def verification_code
    code = params[:verification][:code]
    if code == "friend" || code == "guest" || code == "hec_2015"
      redirect_to new_recommendation_path, notice: "Partage ta première reco avant de découvrir celles de tes amis !"
    else
      redirect_to access_users_path, notice: "Le code n'est pas valide"
    end
  end

end
