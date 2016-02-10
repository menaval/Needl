json.requests               @requests do |request|
  json.name              request.name.split(" ")[0]
  json.picture           request.picture
  json.id                request.id
  json.number_of_recos   Recommendation.where(user_id: request.id).count
end
json.friends                @friends do |friend|
  json.name              friend.name.split(" ")[0]
  json.fullname          friend.name
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
  json.number_of_recos   @friends_recommendations[:friend.id] ? @friends_recommendations[:friend.id].length : 0
  json.recommendations   @friends_recommendations[:friend.id]
  json.wishes            @friends_wishes[:friend.id]
end
json.me do
  json.name              @user.name.split(" ")[0]
  json.fullname          @user.name
  json.picture           @user.picture
  json.id                @user.id
  json.number_of_recos   @friends_recommendations[:@user.id] ? @friends_recommendations[:@user.id].length : 0
  json.recommendations   @friends_recommendations[:@user.id]
  json.wishes            @friends_wishes[:@user.id]
end

