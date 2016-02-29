module Api
  class RegistrationsController < ApplicationController
    # acts_as_token_authentication_handler_for User
    skip_before_action :verify_authenticity_token
    skip_before_filter :authenticate_user!

    def create
      name = params['name']
      puts "#{params['name']}"
      email = params['email']
      password = params['password']
      all_emails = User.all.pluck(:email)
      if all_emails.include?(email)
        render json: {error_message: "account_already_exists"}
      else
        @user = User.new(name: name, email: email, provider: "mail", emails: [email], password: password)
        @user.save
        sign_in @user
        # On track l'arrivée sur Mixpanel

        # @tracker.people.set(@user.id, {
          # "gender" => @user.gender,
          # "name" => @user.name,
          # "$email": @user.email
        # })
        # @tracker.track(@user.id, 'signup', {"user" => @user.name} )
  #
        # On ajoute le nouveau membre sur la mailing liste de mailchimp
        # if @user.email.include?("needlapp.com") == false && Rails.env.development? != true
  #
          # begin
            # @gibbon = Gibbon::Request.new(api_key: ENV['MAILCHIMP_API_KEY'])
            # @list_id = ENV['MAILCHIMP_LIST_ID_NEEDL_USERS']
            # @gibbon.lists(@list_id).members.create(
              # body: {
                # email_address: @user.email,
                # status: "subscribed",
                # merge_fields: {
                  # FNAME: @user.name.partition(" ").first,
                  # LNAME: @user.name.partition(" ").last,
                  # TOKEN: @user.authentication_token,
                  # GENDER: @user.gender
                # }
              # }
            # )
          # rescue Gibbon::MailChimpError
            # puts "error catched --------------------------------------------"
          # end
        # end

        render json: {user: @user, nb_recos: Restaurant.joins(:recommendations).where(recommendations: { user_id: @user.id }).count, nb_wishes: Restaurant.joins(:wishes).where(wishes: {user_id: @user.id}).count}

    end

# La requete sur Postman
# http://localhost:3000/api/registrations.json?user[name]=valentin&user[email]=yolo2@gmail.co&user[password]=12345678&user[password_confirmation]=12345678
    end

    def edit
      # @user = User.find_by(authentication_token: params["user_token"])
      @user = User.find(params['id'])
      if params['email']
        @name = params['name']
        @email = params['email']
        update
      end
    end

    def update

      # On actualise la base de données mailchimp. Ne pas oublier de le faire quand la personne change son oauth token qu'il faut mettre en place également
      mail_encrypted = Digest::MD5.hexdigest(@user.email)
      @gibbon = Gibbon::Request.new(api_key: ENV['MAILCHIMP_API_KEY'])
      @list_id = ENV['MAILCHIMP_LIST_ID_NEEDL_USERS']

      if @user.email == @email


      @gibbon.lists(@list_id).members(mail_encrypted).update(
        body: {
          merge_fields: {
            FNAME: @name.partition(" ").first,
            LNAME: @name.partition(" ").last
          }
        }
      )

      else

        # On ne peut pas actualiser une adresse mail sur mailchimp, il faut supprimer l'utilisateur et le recréer
       @status = @gibbon.lists(@list_id).members(mail_encrypted).retrieve["status"]
       @gibbon.lists(@list_id).members(mail_encrypted).delete
       @gibbon.lists(@list_id).members.create(
         body: {
           email_address: @email,
           status: @status,
           merge_fields: {
             FNAME: @name.partition(" ").first,
             LNAME: @name.partition(" ").last
           }
         }
       )

      end

      @user.update_attributes(name: @name, email: @email)

      redirect_to edit_api_registration_path(:user_email => params["user_email"], :user_token => params["user_token"])

    end

    private

    # def registration_params
    #   params.require(:registration).permit(:, :wish, { strengths: [] }, { ambiences: [] }, { occasions: [] }, { friends_thanking: [] }, { contacts_thanking: [] }, { experts_thanking: [] })
    # end
  end
end