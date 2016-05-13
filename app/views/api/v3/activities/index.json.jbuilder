json.array! @activities do |activity|
  json.user_id                   activity[:user_id]
  json.restaurant_id             activity[:restaurant_id]
  json.date                      activity[:date]
  json.url                       activity[:url]
  json.user_type                 activity[:user_type]
  json.notification_type         activity[:notification_type]
  json.influencer_id             activity[:influencer_id]
  if activity[:notification_type] == "recommendation"
    json.strengths               activity[:strengths]
    json.occasions               activity[:occasions]
    json.friends_thanking          activity[:friends_thanking]
    json.experts_thanking          activity[:experts_thanking]
  end
  json.review                    activity[:review]
end