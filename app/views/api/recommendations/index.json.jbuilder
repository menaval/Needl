json.array! @api_activities do |activity|
  recommendation = activity.trackable
  restaurant = Restaurant.find(recommendation.restaurant_id)
  user = activity.owner
  if activity.owner_type == 'User'
    json.user                    user.name.split(" ")[0]
  else
    json.user                    user.owner.name
  end
  json.user_type                 activity.owner_type
  json.user_picture              user.owner.picture
  json.user_id                   user.owner.id
  json.restaurant_name           restaurant.name
  json.restaurant_picture        restaurant.restaurant_pictures.first ? restaurant.restaurant_pictures.first.picture : restaurant.picture_url
  json.restaurant_id             restaurant.id
  json.restaurant_food           restaurant.food_name
  if restaurant.price_range
    json.restaurant_price_range  restaurant.price_range
  end
  if activity.trackable.is_a? Recommendation
    json.review                  recommendation.review
  end
  json.date                      activity.created_at.strftime('%-d %B')
end