@users.each do |user|
  json.id               user.id
  json.fullname         user.name
  json.picture          user.picture
end