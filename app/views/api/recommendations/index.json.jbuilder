json.array! @api_activities do |activity|
  if activity.trackable.is_a? Recommendation
    @restaurant_id = @all_recommendations_infos[activity.trackable_id][:restaurant_id]
  elsif activity.trackable.is_a? Wish
    @restaurant_id = @all_wishes_infos[activity.trackable_id]
  end
  if activity.owner_type == 'User'
    json.user                    @all_users_infos[activity.owner_id][:name].split(" ")[0]
  else
    json.user                    @all_users_infos[activity.owner_id][:name]
  end
  json.user_type                 activity.owner_type
  json.user_picture              @all_users_infos[activity.owner_id][:picture]
  json.user_id                   activity.owner_id
  json.restaurant_name           @all_restaurants_infos[@restaurant_id][:name]
  json.restaurant_picture        @all_restaurant_pictures_infos[@restaurant_id] ? @all_restaurant_pictures_infos[@restaurant_id].first : @all_restaurants_infos[@restaurant_id][:picture_url]
  json.restaurant_id             @restaurant_id
  json.restaurant_food           @all_restaurants_infos[@restaurant_id][:food_name]
  if restaurant.price_range
    json.restaurant_price_range  @all_restaurants_infos[@restaurant_id][:price_range]
  end
  if activity.trackable.is_a? Recommendation
    json.review                  @all_recommendations_infos[activity.trackable_id][:review]
  end
  json.date                      activity.created_at.strftime('%-d %B')
end