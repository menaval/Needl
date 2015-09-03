class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def facebook
    user = User.find_for_facebook_oauth(request.env["omniauth.auth"])
    if user.token_expiry < Time.now
      user.token = request.env["omniauth.auth"].credentials.token
      user.token_expiry = Time.at(request.env["omniauth.auth"].credentials.expires_at)
      user.save
    end

    if user.persisted?
      sign_in user#, event: :authentication
      if user.sign_in_count == 1
        @tracker.track(current_user.id, 'signup', {"user" => user.name, "browser" => browser.name} )
        redirect_to access_users_path
      else
        @tracker.track(current_user.id, 'signin', {"user" => user.name, "browser" => browser.name} )
        redirect_to root_path
      end

    else
      session["devise.facebook_data"] = request.env["omniauth.auth"]
      redirect_to new_user_registration_url, notice: "Votre adresse mail renseignée sur Facebook est périmée, pour avoir accès à n'importe quelle application via Facebook connect vous devez désormais aller des les paramètres et la changer."
    end
  end

  def facebook_access_token
    user = User.find_for_facebook_oauth(request.env["omniauth.auth"])

    if user.persisted?
      sign_in user#, event: :authentication
      if user.sign_in_count == 1
        @tracker.track(current_user.id, 'signup', {"user" => user.name, "browser" => browser.name} )
      else
        @tracker.track(current_user.id, 'signin', {"user" => user.name, "browser" => browser.name} )
      end

      render json: {user: user, nb_recos: Restaurant.joins(:recommendations).where(recommendations: { user_id: user.id }).count, nb_wishes: Restaurant.joins(:wishes).where(wishes: {user_id: user.id}).count}
    end
  end
end