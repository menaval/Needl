json.array! @api_activities do |activity|
  restaurant = Restaurant.find(activity.trackable.restaurant_id)
  json.user                      activity.owner.name.split(" ")[0]
  json.user_picture              activity.owner.picture
  json.user_id                   activity.owner.id
  json.restaurant_name           restaurant.name
  json.restaurant_picture        restaurant.restaurant_pictures.first ? restaurant.restaurant_pictures.first.picture : restaurant.picture_url
  json.restaurant_id             restaurant.id
  json.restaurant_food           restaurant.food.name
  if restaurant.price_range
    json.restaurant_price_range    restaurant.price_range
  end
  if activity.trackable.is_a? Recommendation
    json.review                    activity.trackable.review == "" ? "Je recommande !" : activity.trackable.review
  end
  json.date                      activity.created_at.strftime('%-d %B')
end