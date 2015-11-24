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
    mail(to: @user.email, subject: "Un des restos préférés de #{@friend.name.split(" ")[0]}")
  end
end
