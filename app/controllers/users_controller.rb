class UsersController < ApplicationController

  def show

    @user = User.find(params[:id])

  end

  # def change_password
  #   @user = User.find_by(authentication_token: params["user_token"])
  #   password = params["password"]
  #   @user.update_attributes(password: password)
  #   render(:json => {notice: "Ton mot de passe a bien été changé !"}, :status => 409, :layout => false)
  # end

end
