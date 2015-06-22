json.potential_friends   @new_potential_friends do |user|
  json.name     user.name.split(" ")[0]
  json.picture  user.picture
  json.number   Recommendation.where(user_id: user.id).length
end