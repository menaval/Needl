json.array!                    @restaurants do |restaurant|
  json.id                   restaurant.id
  json.name                 restaurant.name
  json.address              restaurant.address
  json.latitude             restaurant.latitude
  json.longitude            restaurant.longitude
  if @all_pictures[restaurant.id]
    json.pictures           @all_pictures[restaurant.id]
  else
    json.pictures           [restaurant.picture_url]
  end
  json.food                 [restaurant.food_id, restaurant.food_name]
  json.types                restaurant.types.pluck(:id)
  json.price_range          restaurant.price_range
  json.phone_number         restaurant.phone_number
  if @all_ambiences[restaurant.id]
    json.ambiences           @all_ambiences[restaurant.id].flatten.group_by(&:itself).sort_by { |_id, votes| -votes.length }.first(2).to_h.keys.first(2)
  else
    json.ambiences          []
  end
  if @all_occasions[restaurant.id]
    json.occasions           @all_occasions[restaurant.id].flatten.group_by(&:itself).sort_by { |_id, votes| -votes.length }.first(2).to_h.keys.first(2)
  else
    json.occasions          []
  end
  @all_friends_recommending[restaurant.id] ||= []
  @all_friends_wishing[restaurant.id] ||= []
  if @all_friends_recommending[restaurant.id].include?(553)
    if @all_friends_recommending[restaurant.id].include?(@user.id)
      json.score            restaurant.needl_coefficient + @me_recommending_coefficient + @recommendation_coefficient*(@all_friends_recommending[restaurant.id].length - 2) + @wish_coefficient*(@all_friends_wishing[restaurant.id].length)
    elsif @all_friends_wishing[restaurant.id].include?(@user.id)
      json.score            restaurant.needl_coefficient + @me_wishing_coefficient + @recommendation_coefficient*(@all_friends_recommending[restaurant.id].length - 1) + @wish_coefficient*(@all_friends_wishing[restaurant.id].length - 1)
    else
      json.score            restaurant.needl_coefficient + @recommendation_coefficient*(@all_friends_recommending[restaurant.id].length - 1) + @wish_coefficient*(@all_friends_wishing[restaurant.id].length)
    end
  elsif @all_friends_recommending[restaurant.id].include?(@user.id)
    json.score              @me_recommending_coefficient + @recommendation_coefficient*(@all_friends_recommending[restaurant.id].length - 1) + @wish_coefficient*(@all_friends_wishing[restaurant.id].length)
  elsif @all_friends_wishing[restaurant.id].include?(@user.id)
    json.score              @me_wishing_coefficient + @recommendation_coefficient*(@all_friends_recommending[restaurant.id].length) + @wish_coefficient*(@all_friends_wishing[restaurant.id].length - 1)
  else
    json.score              @recommendation_coefficient*(@all_friends_recommending[restaurant.id].length) + @wish_coefficient*(@all_friends_wishing[restaurant.id].length)
  end

  json.subways                restaurant.subways_near
  json.closest_subway         restaurant.subway_id
  json.friends_recommending   @all_friends_recommending[restaurant.id]
  json.friends_wishing        @all_friends_wishing[restaurant.id]
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

