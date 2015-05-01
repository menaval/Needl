class RestaurantsController < ApplicationController
  def show
    @restaurant = Restaurant.find(params[:id])
  end

  def index
    if params[:query]
      query = params[:query]
      @restaurants = Restaurant.cheaper_than(query[:price]).by_food(query[:food])
    else
      @restaurants = Restaurant.all
    end

    @markers = Gmaps4rails.build_markers(@restaurants) do |restaurant, marker|
      marker.lat restaurant.latitude
      marker.lng restaurant.longitude
      marker.infowindow render_to_string(partial: "map_box", locals: { restaurant: restaurant })
    end
  end
end
