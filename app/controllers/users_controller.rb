class UsersController < ApplicationController

  def show

    @user = User.find(params[:id])

  end

  def update_password
    @user = User.find_by(authentication_token: params["user_token"])
    password = params["password"]
    password_confirmation = params["password_confirmation"]
    if @user.provider == "facebook"
      render(:json => {notice: "Nous ne pouvons pas changer ton mot de passe, tu t'es inscrit via facebook !"}, :status => 409, :layout => false)
    elsif password != password_confirmation
      render(:json => {notice: "Erreur: Les deux mots de passe étaient différents."}, :status => 409, :layout => false)
    else
    @user.update_attributes(password: password)
    render(:json => {notice: "Ton mot de passe a bien été changé !"}, :status => 409, :layout => false)
    end
  end

end
