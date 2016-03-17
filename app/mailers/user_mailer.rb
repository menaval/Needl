class UserMailer < ApplicationMailer

  def welcome(user)
    @user = user
    mail(to: @user.email, subject: 'Hey')
  end

  def new_friend(user, friend)
    @user = user
    @friend = friend
    @restaurant = Restaurant.find(@friend.recommendations.first.restaurant_id)
    @picture = @restaurant.restaurant_pictures.first ? @restaurant.restaurant_pictures.first.picture : @restaurant.picture_url
    if @picture == "restaurant_default.jpg"
      @picture = "https://static.pexels.com/photos/536/road-street-sign-way.jpg"
    end
    @review = @friend.recommendations.first.review
    mail(to: @user.email, subject: "#{@user.name.split(" ")[0]}, je te recommande #{@restaurant.name} sur Needl", from: "#{@friend.name} <valentin.menard@needlapp.com>")
  end

  def invite_contact_with_restaurant(user, contact_mail, contact_name, review, resto_id)

    @user = user
    @contact_name = contact_name
    @restaurant = Restaurant.find(resto_id)
    @picture = @restaurant.restaurant_pictures.first ? @restaurant.restaurant_pictures.first.picture : @restaurant.picture_url
    if @picture == "restaurant_default.jpg"
      @picture = "https://static.pexels.com/photos/536/road-street-sign-way.jpg"
    end
    @review = review

    #  On track les invitations envoyées par mail (avec image)
    @tracker = Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])
    @tracker.track(@user.id, 'Invitation Sent To A Friend', { "invitee name" => @contact_name, "user" => @user.name, "type" => "Mail", "restaurant" => @restaurant.name  })

    mail(to: contact_mail, subject: "#{@contact_name}, je te recommande #{@restaurant.name} sur Needl", from: "#{@user.name} <valentin.menard@needlapp.com>")

  end

  def invite_contact_without_restaurant(user, contact_mail, contact_name)

    @user = user
    @contact_name = contact_name

    #  On track les invitations envoyées par mail (sans image)
    @tracker = Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])
    @tracker.track(@user.id, 'Invitation Sent To A Friend', { "invitee name" => @contact_name, "user" => @user.name, "type" => "Mail", "restaurant" => ""  })

    mail(to: contact_mail, subject: "#{@contact_name}, je t'invite à découvrir mes restaurants préférés sur Needl", from: "#{@user.name} <valentin.menard@needlapp.com>")

  end

  def thank_friends(user, friends_infos, restaurant_id)

    @user = user
    @restaurant = Restaurant.find(restaurant_id)
    @tracker = Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])
    friends_infos.each do |friend_info|
      @friend_name = friend_info[:name]
      friend_mail =  friend_info[:email]
      @tracker.track(@user.id, 'Thanks sent', { "user" => @user.name, "type" => "Mail",  "User Type" => "Friend" })
      mail(to: friend_mail, subject: "#{@friend_name}, merci pour l'adresse !", from: "#{@user.name} <valentin.menard@needlapp.com>")
    end

  end

  def update_password(user)
    @user = user
    @tracker = Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])
    @tracker.track(@user.id, 'Password Forgotten', { "user" => @user.name, "type" => "Mail"})
    mail(to: @user.email, subject: "Réinitialisez votre mot de passe sur Needl", from: "Valentin de Needl <valentin.menard@needlapp.com>")
  end

  # def thank_contacts(user, contacts_infos, restaurant_id)

  #   @user = user
  #   @restaurant = Restaurant.find(restaurant_id)
  #   @tracker = Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])
  #   contacts_infos.each do |contact_info|
  #     @contact_name = contact_info[:name]
  #     contact_mail =  contact_info[:email]
  #     @tracker.track(@user.id, 'Thanks sent', { "user" => @user.name, "type" => "Mail",  "User Type" => "Contact" })
  #     mail(to: contact_mail, subject: "#{@contact_name}, merci pour l'adresse !", from: "#{@user.name} <valentin.menard@needlapp.com>")
  #   end

  # end


end
