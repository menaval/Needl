class UserMailer < ApplicationMailer

  def welcome(user)
    @user = user
    #  a changer la subject line
    mail(to: @user.email, subject: 'Quel bon choix')
  end

  def new_friend(user, friend)
    @user = user
    @friend = friend
    mail(to: @user.email, subject: "#{@friend.name.split(" ")[0]} te fait découvrir ses restos")
  end
end
