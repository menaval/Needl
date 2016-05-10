class Api::V3::RegistrationsController < ApplicationController
      # acts_as_token_authentication_handler_for User
      skip_before_action :verify_authenticity_token
      skip_before_filter :authenticate_user!

      def create
        name = params['name'].downcase.titleize
        puts "#{params['name']}"
        email = params['email'].downcase
        password = params['password']
        all_emails = User.all.pluck(:email)
        if all_emails.include?(email)
          render(json: {error_message: "account_already_exists"}, status: 401)
        else
          @user = User.new(name: name, email: email, provider: "mail", picture: "https://s3-eu-west-1.amazonaws.com/needl/production/supports/no_photo.jpeg", emails: [email], password: password)
          @user.save
          sign_in @user

          # les personnes suivent automatiquement les influenceurs
          User.where(public: true).each do |influencer|
            Followership.create(follower_id: @user.id, following_id: influencer.id)
          end
          # On track l'arrivée sur Mixpanel

          @tracker.people.set(@user.id, {
            "gender" => @user.gender,
            "name" => @user.name,
            "$email": @user.email
          })
          @tracker.track(@user.id, 'signup', {"user" => @user.name} )

          # s'il a reçu un point d'expertise
          if params["friend_id"] != nil && params["restaurant_id"] != nil && Recommendation.where(user_id: params["friend_id"], restaurant_id: params["restaurant_id"]).length > 0
            Friendship.create(sender_id: params["friend_id"], receiver_id: @user.id, accepted: true)
            reco = Recommendation.where(user_id: params["friend_id"], restaurant_id: params["restaurant_id"]).first
            reco.friends_thanking += [@user.id]
            reco.save
            @user.update_attribute(:score, 1)
            puts "------------------------------------------------"
            puts "#{@user.score}"
            @tracker.track(@user.id, 'Signup Thanked', { "user" => @user.name, "friend" => reco.user.name, "restaurant" => reco.restaurant.name})
          end


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

          puts "---------------------------------------------------------"
          puts "#{@user.score}"

          render json: {user: @user, nb_recos: Restaurant.joins(:recommendations).where(recommendations: { user_id: @user.id }).count, nb_wishes: Restaurant.joins(:wishes).where(wishes: {user_id: @user.id}).count}

        end

  # La requete sur Postman
  # http://localhost:3000/api/registrations.json?user[name]=valentin&user[email]=yolo2@gmail.co&user[password]=12345678&user[password_confirmation]=12345678
      end


      private

      # def registration_params
      #   params.require(:registration).permit(:, :wish, { strengths: [] }, { ambiences: [] }, { occasions: [] }, { friends_thanking: [] }, { contacts_thanking: [] }, { experts_thanking: [] })
      # end

end