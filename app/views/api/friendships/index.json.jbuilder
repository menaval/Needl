json.requests               @requests do |request|
  json.name              request.name.split(" ")[0]
  json.picture           request.picture
  json.id                request.id
  json.number_of_recos   Recommendation.where(user_id: request.id).count
end
json.friends                @friends do |friend|
  json.name              friend.name.split(" ")[0]
  json.picture           friend.picture
  json.id                friend.id
  json.score             friend.score
  if @category_1.include?(friend.id)
    json.correspondence_score     1
  elsif @category_2.include?(friend.id)
    json.correspondence_score     2
  elsif @category_3.include?(friend.id)
    json.correspondence_score     3
  end
  json.number_of_recos   Recommendation.where(user_id: friend.id).count
end

