json.id                @restaurant.id
json.name              @restaurant.name
json.food              @restaurant.food.name
json.price_range       @restaurant.price_range
json.address           @restaurant.address
json.ambiences         @restaurant.ambiences_from_my_friends(@user)
json.strengths         @restaurant.strengths_from_my_friends(@user)
json.reviews           @restaurant.reviews_from_my_friends(@user)
json.pictures          @pictures

