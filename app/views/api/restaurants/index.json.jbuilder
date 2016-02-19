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
    if @user.app_version == nil
      json.ambiences           @all_ambiences[restaurant.id].flatten.group_by(&:itself).sort_by { |_id, votes| -votes.length }.first(2).to_h.keys.first(2) - ["4", "5", "6", "7", "8"]
    else
      json.ambiences           @all_ambiences[restaurant.id].flatten.group_by(&:itself).sort_by { |_id, votes| -votes.length }.first(2).to_h.keys.first(2)
    end
  else
    json.ambiences          []
  end
  if @all_occasions[restaurant.id]
    json.occasions           @all_occasions[restaurant.id].flatten.group_by(&:itself).sort_by { |_id, votes| -votes.length }.first(2).to_h.keys.first(2)
  else
    json.occasions          []
  end
  @all_friends_recommending_new_version[restaurant.id] ||= []
  @all_friends_category_1_recommending[restaurant.id] ||= []
  @all_friends_category_2_recommending[restaurant.id] ||= []
  @all_friends_category_3_recommending[restaurant.id] ||= []
  @all_friends_wishing_new_version[restaurant.id] ||= []
  @all_friends_category_1_wishing[restaurant.id] ||= []
  @all_friends_category_2_wishing[restaurant.id] ||= []
  @all_friends_category_3_wishing[restaurant.id] ||= []
  if @all_strengths[restaurant.id]
    json.strengths           @all_strengths[restaurant.id].flatten.group_by(&:itself).sort_by { |_id, votes| -votes.length }.first(2).to_h.keys.first(2)
  else
    json.strengths           []
  end
  @score_from_friends = @recommendation_coefficient_category_1*(@all_friends_category_1_recommending[restaurant.id].length) + @recommendation_coefficient_category_2*(@all_friends_category_2_recommending[restaurant.id].length) +
      @recommendation_coefficient_category_3*(@all_friends_category_3_recommending[restaurant.id].length) + @wish_coefficient_category_1*(@all_friends_category_1_wishing[restaurant.id].length) + @wish_coefficient_category_2*(@all_friends_category_2_wishing[restaurant.id].length) +
      @wish_coefficient_category_3*(@all_friends_category_3_wishing[restaurant.id].length)

  if @all_friends_recommending_new_version[restaurant.id] && @all_friends_recommending_new_version[restaurant.id].map{|x| x[:id]}.include?(553)
    if @all_friends_recommending_new_version[restaurant.id].map{|x| x[:id]}.include?(@user.id)
      json.score            restaurant.needl_coefficient + @me_recommending_coefficient + @score_from_friends
    elsif @all_friends_wishing_new_version[restaurant.id] && @all_friends_wishing_new_version[restaurant.id].include?(@user.id)
      json.score            restaurant.needl_coefficient + @me_wishing_coefficient + @score_from_friends
    else
      json.score            restaurant.needl_coefficient + @score_from_friends
    end
  elsif @all_friends_recommending_new_version[restaurant.id] && @all_friends_recommending_new_version[restaurant.id].map{|x| x[:id]}.include?(@user.id)
    json.score              @me_recommending_coefficient + @score_from_friends
  elsif @all_friends_wishing_new_version[restaurant.id] && @all_friends_wishing_new_version[restaurant.id].map{|x| x[:id]}.include?(@user.id)
    json.score              @me_wishing_coefficient + @score_from_friends
  else
    json.score              @score_from_friends
  end

  json.subways                   restaurant.subways_near
  json.closest_subway            restaurant.subway_id
  json.friends_recommending      @all_friends_recommending[restaurant.id] ? @all_friends_recommending[restaurant.id] : []
  json.friends_wishing           @all_friends_wishing[restaurant.id] ? @all_friends_wishing[restaurant.id] : []
  json.my_friends_recommending   @all_friends_recommending_new_version[restaurant.id]
  json.my_friends_wishing        @all_friends_wishing_new_version[restaurant.id]
  json.starter1                  restaurant.starter1
  json.price_starter1            restaurant.price_starter1
  json.starter2                  restaurant.starter2
  json.price_starter2            restaurant.price_starter2
  json.main_course1              restaurant.main_course1
  json.price_main_course1        restaurant.price_main_course1
  json.main_course2              restaurant.main_course2
  json.price_main_course2        restaurant.price_main_course2
  json.main_course3              restaurant.main_course3
  json.price_main_course3        restaurant.price_main_course3
  json.dessert1                  restaurant.dessert1
  json.price_dessert1            restaurant.price_dessert1
  json.dessert2                  restaurant.dessert2
  json.price_dessert2            restaurant.price_dessert2
end

