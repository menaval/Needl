module Api
  class UsersController < ApplicationController
    # acts_as_token_authentication_handler_for User
    skip_before_action :verify_authenticity_token
    skip_before_filter :authenticate_user!

    def show
      @user = User.find(params["id"].to_i)
      @recos = @user.my_recos
      @wishes = @user.my_wishes
      @myself = User.find_by(authentication_token: params["user_token"])
      if @myself.id != @user.id
        @friendship = Friendship.find_by(sender_id: [@myself.id, @user.id], receiver_id: [@myself.id, @user.id])
        @invisible  = (@friendship.sender_id == @myself.id && @friendship.receiver_invisible == true ) || ( @friendship.receiver_id == @myself.id && @friendship.sender_invisible == true )
      end
    end

    def new_parse_installation

      client = Parse.create(application_id: ENV['PARSE_APPLICATION_ID'], api_key: ENV['PARSE_API_KEY'])
      @user = User.find_by(authentication_token: params["user_token"])
      @device_token = params["device_token"]
      @device_type = params["device_type"]

      # créer l'installation
      installation = client.installation.tap do |i|
        i.device_token = @device_token
        i.device_type = @device_type
        i['user_id'] = @user.id
      end
      installation.save
      redirect_to user_path(@user.id)
    end

    def reset_badge_to_zero
      client = Parse.create(application_id: ENV['PARSE_APPLICATION_ID'], api_key: ENV['PARSE_API_KEY'], master_key:ENV['PARSE_MASTER_KEY'])
      @user = User.find_by(authentication_token: params["user_token"])
      installations = client.query("_Installation").tap do |q|
        q.eq("user_id", @user.id)
      end.get
      installations.each do |installation|
        installation['badge'] = 0
        installation.save
      end
      redirect_to user_path(@user.id)
    end

    def contacts_access
      list = params["contact_list"]
      users = User.all

      users.each do |user|
        list.each do |contact|

          phone_numbers = contact["phoneNumbers"] ? contact["phoneNumbers"].map{|x| x["number"].delete(' ')} : []
          user_phone_numbers = user.phone_numbers
          emails = contact["emailAdresses"] ? contact["emailAdresses"].map{|x| x["email"].downcase.delete(' ')} : []
          user_emails = user.emails

          # On test si on reconnait le user grace aux numéros de tel ou a une adresse mail
          if phone_numbers.any? {|number| user_phone_numbers.include?(number) } || emails.any? {|email| user_emails.include?(email) }

            # on rajoute des mails si pas dans la BDD
            emails.each do |email|
              if user_emails.include?(email) == false
                user_emails << email
                user.save
              end
            end

            # on rajoute des tels si pas dans la BDD
            phone_numbers.each do |number|
              if user_phone_numbers.include?(number) == false
                user_phone_numbers << number
                user.save
              end
            end

          end

        end
      end

    end

    def invite_contact
      user = User.find_by(authentication_token: params["user_token"])
      contact = params["contact"]
      contact_name = contact["givenName"] ? contact["givenName"] : ""
      contact_mail = contact["emailAdresses"] ? contact["emailAdresses"].first.downcase.delete(' ')} : ""
      contact_phone_number = contact["phoneNumbers"] ? contact["phoneNumbers"].first.delete(' ') : ""
      if contact_mail != ""
        user.send_invite_contact_email(contact_mail, contact_name)
      elsif contact_phone_number != ""
        # integration twilio
      end
    end


    def parse_initialization
      client = Parse.init :application_id => ENV['PARSE_APPLICATION_ID'],
                 :api_key => ENV['PARSE_API_KEY']
    end

  end
end