class RestaurantsController < ApplicationController
  def show
    @restaurant = Restaurant.find(params[:id])
  end

  def index

    my_restaurants = current_user.my_friends_restaurants
    if params[:query]
      query = params[:query]
      @restaurants = Restaurant.cheaper_than(query[:price]).by_food(query[:food]) & my_restaurants
      # à rendre plus performant parce que la va tester tous les restos de la base!
    else
      @restaurants = my_restaurants
    end


    @markers = Gmaps4rails.build_markers(@restaurants) do |restaurant, marker|
      marker.lat restaurant.latitude
      marker.lng restaurant.longitude
      marker.infowindow render_to_string(partial: "map_box", locals: { restaurant: restaurant })
    end
  end
end
