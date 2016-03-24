class Api::V2::RegistrationsController < ApplicationController
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
          @user = User.new(name: name, email: email, provider: "mail", picture: "https://s3-eu-west-1.amazonaws.com/needl/production/supports/no_photo.jpeg?X-Amz-Date=20160324T094744Z&X-Amz-Expires=300&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Signature=361833e8982069eef443e88a6e158963037cfe8b66313f018025f5a8bcdd00cc&X-Amz-Credential=ASIAIP5QPA6MMDWTC75A/20160324/eu-west-1/s3/aws4_request&X-Amz-SignedHeaders=Host&x-amz-security-token=AQoDYXdzEEMagALYzsKfi63vCcNg0nd2GFKyYe1mpOjSaortqJJWI0spfzpiL%2B90KT0eVrXXSgY82rVwelxvucGmh9qeZCAN4eQ151xEJYMyWJcJhGIq2QC9L6PkOi0k5yoxpqmFJABuNH0P7aR52pQItVQHMiumN5XJfTdVrlwueFyndRipTzDPx%2BHCryZsTW1LRbTZH4AXxGIla6QM6DIytNKOFIPb64JrcuPDiYMmUdjRIBoqoBsd6OPZw9Rty/0hakH4V/7zj8neqcxPOh4FLpJcD9Gd0q0netJR5KbHxtE1tKmvRwyMsqftqivhgkjhO8HMI3FDeQ5KJx4BZH5a66kk41xABqOCIPHuzrcF", emails: [email], password: password)
          @user.save
          sign_in @user

          # les personnes suivent automatiquement Needl
          Followership.create(follower_id: @user.id, following_id: 553)
          # On track l'arrivée sur Mixpanel

          @tracker.people.set(@user.id, {
            "gender" => @user.gender,
            "name" => @user.name,
            "$email": @user.email
          })
          @tracker.track(@user.id, 'signup', {"user" => @user.name} )

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