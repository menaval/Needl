json.thanks       @recos do |recommendation|
  @friend               = User.find(recommendation.user_id)
  @restaurant           = Restaurant.find(recommendation.restaurant_id)
  json.friend_name      @friend.name
  json.friend_picture   @friend.picture
  json.restaurant_name  @restaurant.name
  json.date             recommendation.created_at.to_date
end