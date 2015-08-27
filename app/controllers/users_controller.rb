class UsersController < ApplicationController

  def show
    @user = User.find(params[:id])
  end


  def verification_code
    code = params[:verification][:code]
    if code == "friend" || code == "guest"
      redirect_to new_recommendation_path, notice: "Partage ta première reco avant de découvrir celles de tes amis !"
    elsif User.find_by(code: code) && User.find_by(code: code) != current_user
      Friendship.create(sender_id: User.find_by(code: code).id, receiver_id: current_user.id, accepted: false)
      redirect_to new_recommendation_path, notice: "Partage ta première reco avant de découvrir celles de tes amis !"
    else
      redirect_to access_users_path, notice: "Le code n'est pas valide"
    end
  end

end
