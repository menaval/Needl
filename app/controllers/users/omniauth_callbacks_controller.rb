class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def facebook
    user = User.find_for_facebook_oauth(request.env["omniauth.auth"])
    if user.token_expiry  && user.token_expiry < Time.now
      user.token = request.env["omniauth.auth"].credentials.token
      user.token_expiry = Time.at(request.env["omniauth.auth"].credentials.expires_at)
      user.save
    end

    # Pour tous ceux qui sont rentrés sur l'app avant qu'on mette e système pour récupérer la date de naissance
    # if user.birthday == nil
    #   user.birthday = Date.parse(request.env["omniauth.auth"].extra.raw_info.birthday)
    #   user.save
    # end

    if user.persisted?
      sign_in user#, event: :authentication
      if user.sign_in_count == 1
        @tracker.track(current_user.id, 'signup', {"user" => user.name} )
        redirect_to new_recommendation_path, notice: "Partage ta première reco avant de découvrir celles de tes amis"
      else
        @tracker.track(current_user.id, 'signin', {"user" => user.name} )

        redirect_to root_path
      end

    else
      session["devise.facebook_data"] = request.env["omniauth.auth"]
      redirect_to new_user_registration_url, notice: "Votre adresse mail renseignée sur Facebook est périmée, pour avoir accès à n'importe quelle application via Facebook connect vous devez désormais aller des les paramètres et la changer."
    end
  end

  def facebook_access_token
    if params["link_to_facebook"] == "true"
      link_account_to_facebook(request.env["omniauth.auth"])
    else
      @user = User.find_for_facebook_oauth(request.env["omniauth.auth"])
      #  Pas hyper sur que ca serve a quelque chose puisque les nouvelles personnes n'ont pas d'expire_at
      if @user.token_expiry && @user.token_expiry < Time.now
        @user.token = request.env["omniauth.auth"].credentials.token
        if request.env["omniauth.auth"].credentials.expires_at
          @user.token_expiry = Time.at(request.env["omniauth.auth"].credentials.expires_at)
        else
          @user.token_expiry = nil
        end
        @user.save
      end

      puts "#{request.env["omniauth.auth"]}"

      # Pour tous ceux qui sont rentrés sur l'app avant qu'on mette e système pour récupérer la date de naissance
      # if @user.birthday == nil
      #   @user.birthday = Date.parse(request.env["omniauth.auth"].extra.raw_info.birthday)
      #   @user.save
      # end

      if @user.persisted?
        puts "user persisted"
        sign_in @user#, event: :authentication

        # Si c'est un signup

        if @user.sign_in_count == 2

          # On track l'arrivée sur Mixpanel

          # automatiquement il suit Needl à son arrivée
          Followership.create(follower_id: @user.id, following_id: 553)

          @tracker.people.set(@user.id, {
            "gender" => @user.gender,
            "name" => @user.name,
            "$email": @user.email
          })
          @tracker.track(@user.id, 'signup', {"user" => @user.name} )

          accept_all_friends

          # On ajoute le nouveau membre sur la mailing liste de mailchimp
          if @user.email.include?("needlapp.com") == false && Rails.env.development? != true

            begin
              @gibbon = Gibbon::Request.new(api_key: ENV['MAILCHIMP_API_KEY'])
              @list_id = ENV['MAILCHIMP_LIST_ID_NEEDL_USERS']
              @gibbon.lists(@list_id).members.create(
                body: {
                  email_address: @user.email,
                  status: "subscribed",
                  merge_fields: {
                    FNAME: @user.name.partition(" ").first,
                    LNAME: @user.name.partition(" ").last,
                    TOKEN: @user.authentication_token,
                    GENDER: @user.gender ? @user.gender : ""
                  }
                }
              )
            rescue Gibbon::MailChimpError
              puts "error catched --------------------------------------------"
            end

          end
      #  Si c'est un login
        else
          @tracker.track(@user.id, 'signin', {"user" => @user.name} )
        end
        render json: {user: @user, nb_recos: Restaurant.joins(:recommendations).where(recommendations: { user_id: @user.id }).count, nb_wishes: Restaurant.joins(:wishes).where(wishes: {user_id: @user.id}).count}
      else
        puts "user rejected"
      end
    end
  end

  def link_account_to_facebook(auth)
    @user = User.find_by(authentication_token: params["user_token"])
    @user.link_account_to_facebook(auth)
    @tracker.track(@user.id, 'Account Linked to Facebook', {"user" => @user.name} )
    accept_new_friends
    render json: {message: "success"}
    # renvoyer des infos particulières ? (les activités, restaurants et profils de chaque nouvel utilisateur j'imagine)
  end

  def accept_all_friends
    friends = @user.user_friends
    if friends.length > 0
      friends.each do |friend|
        Friendship.create(sender_id: @user.id, receiver_id: friend.id, accepted: true)
        TasteCorrespondence.create(member_one_id: @user.id, member_two_id: friend.id, number_of_shared_restaurants: 0, category: 1)
        @tracker.track(@user.id, 'add_friend', { "user" => @user.name })
      end
    end
  end

  def accept_new_friends
    friends = @user.user_friends
    if friends.length > 0
      friends.each do |friend|
        if Friendship.where(sender_id: [@user.id, friend.id], receiver_id: [@user.id, friend.id]).length == 0
          Friendship.create(sender_id: @user.id, receiver_id: friend.id, accepted: true)
          TasteCorrespondence.create(member_one_id: @user.id, member_two_id: friend.id, number_of_shared_restaurants: 0, category: 1)
          @tracker.track(@user.id, 'add_friend', { "user" => @user.name })
        end
      end
    end
  end

end