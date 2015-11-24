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
        redirect_to new_recommendation_path, notice: "Partage ta première reco avant de découvrir celles de tes amis"
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
    @user = User.find_for_facebook_oauth(request.env["omniauth.auth"])
    # if @user.token_expiry < Time.now
    #   @user.token = request.env["omniauth.auth"].credentials.token
    #   @user.token_expiry = Time.at(request.env["omniauth.auth"].credentials.expires_at)
    #   @user.save
    # end

    if user.persisted?
      sign_in @user#, event: :authentication

      # Si c'est un signup

      if @user.sign_in_count == 1

        # On track l'arrivée sur Mixpanel

        @tracker.people.set(user.id, {
          "gender" => @user.gender,
          "name" => @user.name,
          "age" => @user.age_range,
          "$email": @user.email
        })
        @tracker.track(user.id, 'signup', {"user" => @user.name, "browser" => browser.name} )

        # On ajoute le nouveau membre sur la mailing liste de mailchimp

        @gibbon = Gibbon::Request.new(api_key: ENV['MAILCHIMP_API_KEY'])
        @list_id = ENV['MAILCHIMP_LIST_ID_NEEDL_USERS']

        @gibbon.lists(@list_id).members.create(
          body: {
            email_address: @user.email,
            status: "subscribed",
            merge_fields: {
              FNAME: @user.name.partition(" ").first,
              LNAME: @user.name.partition(" ").last
            }
          }
        )

      accept_all_friends

      #  Si c'est un login

      else
        @tracker.track(@user.id, 'signin', {"user" => @user.name, "browser" => browser.name} )
      end

      render json: {user: @user, nb_recos: Restaurant.joins(:recommendations).where(recommendations: { user_id: @user.id }).count, nb_wishes: Restaurant.joins(:wishes).where(wishes: {user_id: @user.id}).count}
    end
  end

  def accept_all_friends
    friends = @user.user_friends
    if friends.length > 0
      friends.each do |friend|
        Friendship.create(sender_id: @user.id, receiver_id: friend.id, accepted: true)
        @tracker.track(@user.id, 'add_friend', { "user" => @user.name })
      end
    end

  end

end