json.id                         @restaurant.id
json.name                       @restaurant.name
json.address                    @restaurant.address
json.latitude                   @restaurant.latitude
json.longitude                  @restaurant.longitude
json.pictures                   @pictures
json.food                       [@restaurant.food_id, @restaurant.food_name]
json.types                      @restaurant.types.pluck(:id)
json.price_range                @restaurant.price_range
json.phone_number               @restaurant.phone_number
json.occasions                  @restaurant.occasions_from_my_friends_and_experts_api(@user)
json.strengths                  @restaurant.strengths_from_my_friends_and_experts_api(@user)

@all_friends_category_1_recommending[@restaurant.id] ||= []
@all_friends_category_2_recommending[@restaurant.id] ||= []
@all_friends_category_3_recommending[@restaurant.id] ||= []
@all_experts_recommending[@restaurant.id] ||= []
@all_friends_category_1_wishing[@restaurant.id] ||= []
@all_friends_category_2_wishing[@restaurant.id] ||= []
@all_friends_category_3_wishing[@restaurant.id] ||= []
@score_from_friends = @recommendation_coefficient_category_1*(@all_friends_category_1_recommending[@restaurant.id].length) + @recommendation_coefficient_category_2*(@all_friends_category_2_recommending[@restaurant.id].length) +
@recommendation_coefficient_category_3*(@all_friends_category_3_recommending[@restaurant.id].length) + @wish_coefficient_category_1*(@all_friends_category_1_wishing[@restaurant.id].length) + @wish_coefficient_category_2*(@all_friends_category_2_wishing[@restaurant.id].length) + @wish_coefficient_category_3*(@all_friends_category_3_wishing[@restaurant.id].length)
@score_from_experts = @recommendation_coefficient_expert*@all_experts_recommending[@restaurant.id].length

  if @all_friends_and_experts_recommending.include?(@user.id)
    json.score              @me_recommending_coefficient + @score_from_friends + @score_from_experts
  elsif @all_friends_wishing.include?(@user.id)
    json.score              @me_wishing_coefficient + @score_from_friends + @score_from_experts
  else
    json.score              @score_from_friends + @score_from_experts
  end

json.subways                    @restaurant.subways_near
json.closest_subway             @restaurant.subway_id
json.my_friends_recommending    @all_friends_and_experts_recommending
json.my_friends_wishing         @all_friends_wishing
json.starter1                   @restaurant.starter1
json.description_starter1       @restaurant.description_starter1
json.price_starter1             @restaurant.price_starter1
json.starter2                   @restaurant.starter2
json.description_starter2       @restaurant.description_starter2
json.price_starter2             @restaurant.price_starter2
json.main_course1               @restaurant.main_course1
json.description_main_course1   @restaurant.description_main_course1
json.price_main_course1         @restaurant.price_main_course1
json.main_course2               @restaurant.main_course2
json.description_main_course2   @restaurant.description_main_course2
json.price_main_course2         @restaurant.price_main_course2
json.main_course3               @restaurant.main_course3
json.description_main_course3   @restaurant.description_main_course3
json.price_main_course3         @restaurant.price_main_course3
json.dessert1                   @restaurant.dessert1
json.description_dessert1       @restaurant.description_dessert1
json.price_dessert1             @restaurant.price_dessert1
json.dessert2                   @restaurant.dessert2
json.description_dessert2       @restaurant.description_dessert2
json.price_dessert2             @restaurant.price_dessert2





