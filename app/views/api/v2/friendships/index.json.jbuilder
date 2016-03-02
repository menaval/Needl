json.requests               @requests do |request|
  json.name              request.name.split(" ")[0]
  json.picture           request.picture
  json.id                request.id
end
json.friends                @friends do |friend|
  json.id                friend.id
  json.name              friend.name.split(" ")[0]
  json.fullname          friend.name
  json.picture           friend.picture
  json.score             friend.score
  json.invisible         @invisibility[friend.id]
  if @category_1.include?(friend.id)
    json.correspondence_score     1
  elsif @category_2.include?(friend.id)
    json.correspondence_score     2
  elsif @category_3.include?(friend.id)
    json.correspondence_score     3
  end
  json.recommendations            @friends_recommendations[friend.id] ? @friends_recommendations[friend.id] : []
  json.wishes                     @friends_wishes[friend.id] ? @friends_wishes[friend.id] : []
  json.followings                 @all_followings[friend.id] ? @all_followings[friend.id] : []
  json.public                     friend.public
  json.public_score               friend.public_score
  json.number_of_followers        @all_followers[friend.id] ? @all_followers[friend.id].length : 0
  json.description                friend.description
  json.tags                       friend.tags
  json.public_recommendations     @all_public_recos[friend.id] ? @all_public_recos[friend.id] : []
  json.url                        friend.url
end


