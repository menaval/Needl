json.id                   @restaurant.id
json.name                 @restaurant.name
json.food                 @restaurant.food.name
json.price_range          @restaurant.price_range
json.address              @restaurant.address
json.pictures             @pictures
json.ambiences            @restaurant.ambiences_from_my_friends(@user)
json.strengths            @restaurant.strengths_from_my_friends(@user)
json.reviews              @restaurant.reviews_from_my_friends(@user)
json.starter1             @restaurant.starter1
json.price_starter1       @restaurant.price_starter1
json.starter2             @restaurant.starter2
json.price_starter2       @restaurant.price_starter2
json.main_course1         @restaurant.main_course1
json.price_main_course1   @restaurant.price_main_course1
json.main_course2         @restaurant.main_course2
json.price_main_course2   @restaurant.price_main_course2
json.main_course3         @restaurant.main_course3
json.price_main_course3   @restaurant.price_main_course3
json.dessert1             @restaurant.dessert1
json.price_dessert1       @restaurant.price_dessert1
json.dessert2             @restaurant.dessert2
json.price_dessert2       @restaurant.price_dessert2


