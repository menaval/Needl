module Api
  class RegistrationsController < ApplicationController
    # acts_as_token_authentication_handler_for User
    skip_before_action :verify_authenticity_token


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
  end
end