json.array!             @restaurants do |restaurant|
  json.id            restaurant.id
  json.name          restaurant.name
  json.address       restaurant.address
  json.latitude      restaurant.latitude
  json.longitude     restaurant.longitude
  json.picture       restaurant.restaurant_pictures.first ? restaurant.restaurant_pictures.first.picture : restaurant.picture_url
  json.pictures      restaurant.restaurant_pictures.first ? restaurant.restaurant_pictures.map {|element| element.picture} : [restaurant.picture_url]
  json.ambiences      restaurant.ambiences_from_my_friends(@user)
  json.strengths      restaurant.strengths_from_my_friends(@user)
  json.reviews        restaurant.reviews_from_my_friends(@user)
  json.food           restaurant.food.name
  json.price_range    restaurant.price_range
end