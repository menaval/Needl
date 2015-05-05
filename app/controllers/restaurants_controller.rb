class RestaurantsController < ApplicationController
  def show
    @restaurant = Restaurant.find(params[:id])
  end

  def index
    query         = params[:query]
    @restaurants  = current_user.my_friends_restaurants

    if query
      @restaurants = @restaurants.cheaper_than(query[:price]).by_food(query[:food])
    end


    @markers = Gmaps4rails.build_markers(@restaurants) do |restaurant, marker|
      marker.lat restaurant.latitude
      marker.lng restaurant.longitude
      marker.infowindow render_to_string(partial: "map_box", locals: { restaurant: restaurant })
    end
  end
end
