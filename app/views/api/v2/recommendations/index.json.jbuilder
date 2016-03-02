json.array! @activities do |activity|
  json.user_id                   activity[:user_id]
  json.restaurant_id             activity[:restaurant_id]
  json.date                      activity[:date]
  json.user_type                 activity[:user_type]
  json.notification_type         activity[:notification_type]
end