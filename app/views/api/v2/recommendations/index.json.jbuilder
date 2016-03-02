json.array! @api_activities do |activity|

  if activity.trackable_type == "Recommendation"
    @restaurant_id = @all_recommendations_infos[activity.trackable_id]
  elsif activity.trackable_type == "Wish"
    @restaurant_id = @all_wishes_infos[activity.trackable_id]
  end
  json.user_id                   activity.owner_id
  json.restaurant_id             @restaurant_id
  json.date                      activity.created_at
  json.user_type                 @all_users_type[activity.owner_id]
  json.notification_type         activity.trackable_type

end