class UserMailer < ApplicationMailer

  def welcome(user)
    @user = user

    #  a changer la subject line
    mail(to: @user.email, subject: 'Très bonne idée')
  end
end
