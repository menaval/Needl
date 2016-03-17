class UsersController < ApplicationController

  def show

    @user = User.find(params[:id])

  end

  # def change_password
  #   @user = User.find_by(authentication_token: params["user_token"])
  # end

  # def update_password
  #   @user = User.find_by(authentication_token: params["user_token"])
  #   password = params["password"]
  #   password_confirmation = params["password_confirmation"]
  #   @user.update_attributes(password: password)
  #   if pass
  #   render(:json => {notice: "Ton mot de passe a bien été changé !"}, :status => 409, :layout => false)
  # end

end
