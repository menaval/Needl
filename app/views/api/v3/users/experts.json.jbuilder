json.experts           @all_experts do |expert|
  json.id                      expert.id
  json.name                    expert.name.split(" ")[0]
  json.fullname                expert.name
  json.picture                 expert.picture
  json.score                   expert.score
  json.invisible               false
  json.correspondence_score    0
  json.mutual_restaurants      @mutual_restaurants[expert.id]
  json.recommendations         @experts_recommendations[expert.id] ? @experts_recommendations[expert.id] : []
  json.wishes                  @experts_wishes[expert.id] ? @experts_wishes[expert.id] : []
  json.followings              @experts_followings[expert.id] ? @experts_followings : []
  json.public                  expert.public
  json.public_score            expert.public_score
  json.number_of_followers     @experts_followers[expert.id] ? @experts_followers[expert.id].length : 0
  json.description             expert.description
  json.tags                    expert.tags
  json.public_recommendations  @experts_public_recommendations[expert.id] ? @experts_public_recommendations[expert.id] : []
  json.url                     expert.url
end

json.restaurants       @restaurants do |restaurant|
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
  json.types                @all_types[restaurant.id]
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
  if @all_strengths[restaurant.id]
    json.strengths           @all_strengths[restaurant.id].flatten.group_by(&:itself).sort_by { |_id, votes| -votes.length }.first(2).to_h.keys.first(2)
  else
    json.strengths           []
  end
  @all_friends_and_experts_recommending[restaurant.id] ||= []
  @all_friends_category_1_recommending[restaurant.id] ||= []
  @all_friends_category_2_recommending[restaurant.id] ||= []
  @all_friends_category_3_recommending[restaurant.id] ||= []
  @all_experts_recommending[restaurant.id] ||= []
  @all_friends_wishing[restaurant.id] ||= []
  @all_friends_category_1_wishing[restaurant.id] ||= []
  @all_friends_category_2_wishing[restaurant.id] ||= []
  @all_friends_category_3_wishing[restaurant.id] ||= []
  @score_from_friends = @recommendation_coefficient_category_1*(@all_friends_category_1_recommending[restaurant.id].length) + @recommendation_coefficient_category_2*(@all_friends_category_2_recommending[restaurant.id].length) +
      @recommendation_coefficient_category_3*(@all_friends_category_3_recommending[restaurant.id].length) + @wish_coefficient_category_1*(@all_friends_category_1_wishing[restaurant.id].length) + @wish_coefficient_category_2*(@all_friends_category_2_wishing[restaurant.id].length) +
      @wish_coefficient_category_3*(@all_friends_category_3_wishing[restaurant.id].length)
  @score_from_experts = @recommendation_coefficient_expert*@all_experts_recommending[restaurant.id].length

  if @all_friends_and_experts_recommending[restaurant.id].include?(@user.id)
    json.score              @me_recommending_coefficient + @score_from_friends + @score_from_experts
  elsif @all_friends_wishing[restaurant.id].include?(@user.id)
    json.score              @me_wishing_coefficient + @score_from_friends + @score_from_experts
  else
    json.score              @score_from_friends + @score_from_experts
  end

  json.subways                   restaurant.subways_near
  json.closest_subway            restaurant.subway_id
  json.my_friends_recommending   @all_friends_and_experts_recommending[restaurant.id]
  json.my_friends_wishing        @all_friends_wishing[restaurant.id]
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