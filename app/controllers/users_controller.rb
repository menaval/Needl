class UsersController < ApplicationController

  def show
    @user = User.find(params[:id])
    User.all.each do |user|
      if user.token_expiry < Time.now
        user.token = request.env["omniauth.auth"].credentials.token
        user.token_expiry = Time.at(request.env["omniauth.auth"].credentials.expires_at)
        user.save
      end
    end
  end

end
