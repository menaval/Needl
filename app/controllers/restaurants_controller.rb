class RestaurantsController < ApplicationController
  def show
    @restaurant = Restaurant.find(params[:id])
  end

  def index
    query = params[:query]

    @restaurants = Restaurant.cheaper_than(query[:max_price]).by_ambience(query[:ambience]).by_strength(query[:strength])
    #.by_food(query[:food])

    @markers = Gmaps4rails.build_markers(@restaurants) do |restaurant, marker|
      marker.lat restaurant.latitude
      marker.lng restaurant.longitude
    end
  end
end
