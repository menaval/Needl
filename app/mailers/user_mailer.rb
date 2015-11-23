class UserMailer < ApplicationMailer

  def welcome(user)
    @user = user
    #  a changer la subject line
    mail(to: @user.email, subject: 'Quel bon choix')
  end

  def new_friend(user, friend)
    @user = user
    @friend = friend
    @friend_first_restaurant = Restaurant.find(@friend.recommendations.first.restaurant_id)
    @friend_first_restaurant_picture = @friend_first_restaurant.restaurant_pictures.first ? @friend_first_restaurant.restaurant_pictures.first : @friend_first_restaurant.picture_url
    @friend_first_restaurant_review = @friend.recommendations.first.review
    mail(to: @user.email, subject: "#{@friend.name.split(" ")[0]} te fait découvrir ses restos")
  end
end
