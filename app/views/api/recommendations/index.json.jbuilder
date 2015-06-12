json.array! @api_activities do |activity|
  restaurant = Restaurant.find(activity.trackable.restaurant_id)
  json.user              activity.owner.name.split(" ")[0]
  json.user_picture      activity.owner.picture
  json.restaurant_name   restaurant.name
  json.restaurant_food   restaurant.food.name
  json.restaurant_price  restaurant.price
  json.review            activity.trackable.review

end