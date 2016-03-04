module Api
  class UsersController < ApplicationController
    acts_as_token_authentication_handler_for User
    skip_before_action :verify_authenticity_token
    skip_before_filter :authenticate_user!

    require 'twilio-ruby'

    def show
      @user = User.find(params["id"].to_i)
      @recos = @user.my_recos
      @wishes = @user.my_wishes
      @myself = User.find_by(authentication_token: params["user_token"])
      @restaurants_recommended_ids = Restaurant.joins(:recommendations).where(recommendations: {user_id: @user.id}).length > 0 ? Restaurant.joins(:recommendations).where(recommendations: {user_id: @user.id}).pluck(:id) : []
      @restaurants_wished_ids = Restaurant.joins(:wishes).where(wishes: {user_id: @user.id}).length > 0 ? Restaurant.joins(:wishes).where(wishes: {user_id: @user.id}).pluck(:id) : []
      # le user.id != 533 c'est pour empêcher une erreur qui devrait disparaitre avec la grosse update de gregoire
      if @myself.id != @user.id && @user.id != 553
        @friendship = Friendship.find_by(sender_id: [@myself.id, @user.id], receiver_id: [@myself.id, @user.id])
        @invisible  = (@friendship.sender_id == @myself.id && @friendship.receiver_invisible == true ) || ( @friendship.receiver_id == @myself.id && @friendship.sender_invisible == true )
         @correspondence_score =  TasteCorrespondence.where("member_one_id = ? and member_two_id = ? or member_one_id = ? and member_two_id = ?", @user.id, @myself.id, @myself.id, @user.id).first.category
      end
      if @user.public == true
        @public_recos = @user.my_public_recos
        @followers = @user.followers
      end
    end

    def score
      @user = User.find(params["id"].to_i)
      @recos = Recommendation.find_by_sql("SELECT * FROM recommendations WHERE recommendations.friends_thanking @> '{#{@user.id}}'")
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
        if params["device_type"] == "android"
          i.push_type = "gcm"
          i.gcm_sender_id = ENV['PARSE_GCM_SENDER_ID']
        end
        i['user_id'] = @user.id
      end
      installation.save
      render json: {message: "success"}
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
      render json: {message: "success"}
    end

    def contacts_access
      @user = User.find_by(authentication_token: params["user_token"])
      list = params["contact_list"]
      users = User.all

      redirect_to new_api_friendship_path(:user_email => params["user_email"], :user_token => params["user_token"])
      ImportedContact.create(user_id: @user.id, list: list, imported: false)

    end

    def update_version
      @user = User.find_by(authentication_token: params["user_token"])
      app_version = params["version"]
      @user.app_version = app_version
      @user.platform = params["platform"]
      @user.save
      @last_version = @user.app_version == "2.0.2" && @user.platform == "ios"
    end

    def invite_contact

      @user = User.find_by(authentication_token: params["user_token"])
      contact = params["contact"]
      redirect_to new_api_friendship_path(:user_email => params["user_email"], :user_token => params["user_token"])

      @contact_name = contact[:givenName] ? contact[:givenName] : ""
      contact_mail = contact[:emailAddresses] ? contact[:emailAddresses].first[:email].downcase.delete(' ') : ""
      @contact_phone_number = contact[:phoneNumbers] ? contact[:phoneNumbers].first[:number] : ""

      recos = @user.recommendations
      recos_commented = recos.map {|x| [x.review, x.restaurant_id] if x.review != "Je recommande !"}.compact

      # On envoie un mail si on l'a
      if contact_mail != ""

        #  on fait en sorte de mettre en priorité les recos qui ont des commentaires
        if recos_commented.length > 0
          @review = recos_commented.first[0]
          @resto_id = recos_commented.first[1]
          @user.send_invite_contact_with_restaurant_email(contact_mail, @contact_name, @review, @resto_id)
        elsif recos.length > 0
          @review = recos.first.review
          @resto_id = recos.first.restaurant_id
          @user.send_invite_contact_with_restaurant_email(contact_mail, @contact_name, @review, @resto_id)
        else
          @user.send_invite_contact_without_restaurant_email(contact_mail, contact_phone)
        end

        # si on n'a pas l'adresse mail, on envoie un texto
      elsif @contact_phone_number != ""

        @contact_phone_number = @contact_phone_number.gsub(/[^0-9+]/, '').gsub(/^00/,"+").gsub(/^0/,"+33")

        if recos_commented.length > 0
          @review = recos_commented.first[0]
          @resto_id = recos_commented.first[1]
          send_text_invitation_with_restaurant
        elsif recos.length > 0
          @review = recos.first.review
          @resto_id = recos.first.restaurant_id
          send_text_invitation_with_restaurant
        else
          send_text_invitation_without_restaurant
        end


      end
    end

    def send_text_invitation_with_restaurant

      restaurant = Restaurant.find(@resto_id)
      account_sid = ENV['TWILIO_SID']
      auth_token  = ENV['TWILIO_AUTH_TOKEN']
      client = Twilio::REST::Client.new account_sid, auth_token

      #  On track les invitations envoyées par texto (avec image)
      @tracker.track(@user.id, 'Invitation Sent To A Friend', { "invitee name" => @contact_name, "user" => @user.name, "type" => "Text", "restaurant" => restaurant.name  })

      client.messages.create(
        from: "Needl",
        to: @contact_phone_number,
        body: "Salut #{I18n.transliterate(@contact_name)}, #{I18n.transliterate(@user.name)} te recommande #{I18n.transliterate(restaurant.name)} pour aller dîner ! #{@review == 'Je recommande !' ? '' : 'Je cite: '}#{@review == 'Je recommande !' ? '' : I18n.transliterate(@review)}#{['!','.', '?'].include?(@review.last) ? '' : '.'} Tu peux retrouver tous ses autres restaurants preferes sur l'app Needl depuis needl.fr !"
      )

    end

    def send_text_invitation_without_restaurant
      account_sid = ENV['TWILIO_SID']
      auth_token  = ENV['TWILIO_AUTH_TOKEN']
      client = Twilio::REST::Client.new account_sid, auth_token

      #  On track les invitations envoyées par texto (sans image)
      @tracker.track(@user.id, 'Invitation Sent To A Friend', { "invitee name" => @contact_name, "user" => @user.name, "type" => "Text", "restaurant" => ""  })

      client.messages.create(
        from: "Needl",
        to: @contact_phone_number,
        body: "#{I18n.transliterate(@user.name)} t'invite a decouvrir ses restaurants preferes sur l'app Needl depuis needl.fr !"
      )

    end


    def parse_initialization
      client = Parse.init :application_id => ENV['PARSE_APPLICATION_ID'],
                 :api_key => ENV['PARSE_API_KEY']
    end

  end
end