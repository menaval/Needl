json.array! @api_activities do |activity|
  restaurant = Restaurant.find(activity.trackable.restaurant_id)
  json.user                      activity.owner.name.split(" ")[0]
  json.user_picture              activity.owner.picture
  json.restaurant_name           restaurant.name
  json.restaurant_picture        restaurant.restaurant_pictures.first ? restaurant.restaurant_pictures.first.picture : restaurant.picture_url
  json.restaurant_id             restaurant.id
  json.restaurant_food           restaurant.food.name
  json.restaurant_price_range    restaurant.price_range
  json.review                    activity.trackable.review
  json.date                      activity.created_at.strftime('%-d %B')

end