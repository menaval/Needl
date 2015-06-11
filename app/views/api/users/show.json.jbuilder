json.id @user.id
json.name @user.name
json.number_of_recos @number
json.picture @user.picture
json.restaurants @restaurants do |restaurant|
  json.id restaurant.id
  json.name restaurant.name
  json.address restaurant.address
  json.picture restaurant.restaurant_pictures.first ? restaurant.restaurant_pictures.first.picture : restaurant.picture_url
end
