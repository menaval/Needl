json.id                    @expert.id
json.name                  @expert.name
json.number_of_recos       @expert.recommendations.length
json.picture               @expert.picture
json.recommendations       @recos do |restaurant|
  json.id               restaurant.id
  json.name             restaurant.name
  json.address          restaurant.address
  json.type             restaurant.food.name
  json.price_range      restaurant.price_range
  json.picture          restaurant.restaurant_pictures.first ? restaurant.restaurant_pictures.first.picture : restaurant.picture_url
  json.review           Recommendation.find_by(restaurant_id: restaurant.id, expert_id: @expert.id).review
end
