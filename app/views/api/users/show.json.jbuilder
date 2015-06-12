json.id                    @user.id
json.name                  @user.name
json.email                 @user.email
json.authentication_token  @user.authentication_token
json.number_of_recos       @restaurants.length
json.picture               @user.picture
json.restaurants           @restaurants do |restaurant|
  json.id       restaurant.id
  json.name     restaurant.name
  json.address  restaurant.address
  json.picture  restaurant.restaurant_pictures.first ? restaurant.restaurant_pictures.first.picture : restaurant.picture_url
  json.review  Recommendation.where(restaurant_id: restaurant.id, user_id: @user.id).first.review
end
