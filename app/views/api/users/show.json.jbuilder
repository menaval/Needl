json.id                    @user.id
json.name                  @user.name
json.email                 @user.email
json.authentication_token  @user.authentication_token
json.number_of_recos       @recos.length
json.score                 @user.score
json.picture               @user.picture
if @user.id != @myself.id
  json.invisible               @invisible
  json.correspondence_score    @correspondence_score
end
json.recommendations       @recos do |restaurant|
  json.id               restaurant.id
  json.name             restaurant.name
  json.address          restaurant.address
  json.latitude         restaurant.latitude
  json.longitude        restaurant.longitude
  json.type             restaurant.food.name
  json.price_range      restaurant.price_range
  json.picture          restaurant.restaurant_pictures.first ? restaurant.restaurant_pictures.first.picture : restaurant.picture_url
  json.review           Recommendation.where(restaurant_id: restaurant.id, user_id: @user.id).first.review
end
json.wishes                @wishes do |restaurant|
  json.id               restaurant.id
  json.name             restaurant.name
  json.address          restaurant.address
  json.latitude         restaurant.latitude
  json.longitude        restaurant.longitude
  json.type             restaurant.food.name
  json.price_range      restaurant.price_range
  json.picture          restaurant.restaurant_pictures.first ? restaurant.restaurant_pictures.first.picture : restaurant.picture_url
end

