json.array!                    @restaurants do |restaurant|
  json.id                   restaurant.id
  json.name                 restaurant.name
  json.address              restaurant.address
  json.latitude             restaurant.latitude
  json.longitude            restaurant.longitude
  json.pictures             restaurant.restaurant_pictures.first ? restaurant.restaurant_pictures.map {|element| element.picture} : [restaurant.picture_url]
  json.food                 @all_foods[restaurant.id]
  json.price_range          restaurant.price_range
  if @all_ambiences[restaurant.id]
    json.ambiences           @all_ambiences[restaurant.id].flatten.group_by(&:itself).sort_by { |_id, votes| -votes.length }.first(2).to_h.keys.first(2)
  end
  json.subways              @all_subways[restaurant.id]
  json.friends_recommending User.joins(:recommendations).where(recommendations: { restaurant_id: restaurant.id }).pluck(:id)
  json.friends_wishing      User.joins(:wishes).where(wishes: { restaurant_id: restaurant.id }).pluck(:id)
  json.starter1             restaurant.starter1
  json.price_starter1       restaurant.price_starter1
  json.starter2             restaurant.starter2
  json.price_starter2       restaurant.price_starter2
  json.main_course1         restaurant.main_course1
  json.price_main_course1   restaurant.price_main_course1
  json.main_course2         restaurant.main_course2
  json.price_main_course2   restaurant.price_main_course2
  json.main_course3         restaurant.main_course3
  json.price_main_course3   restaurant.price_main_course3
  json.dessert1             restaurant.dessert1
  json.price_dessert1       restaurant.price_dessert1
  json.dessert2             restaurant.dessert2
  json.price_dessert2       restaurant.price_dessert2
end