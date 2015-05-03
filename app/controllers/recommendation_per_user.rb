class RecommendationPerUserController < ApplicationController

  def create

  end

  def show
    @restaurant = RecommendationPerUser.find(params[:id]).restaurant
    @restaurant_per_user = RecommendationPerUser.find(params[:id])
  end

  def index

    if params[:query]
      query = params[:query]
      @restaurants = current_user.my_friends_restaurants.cheaper_than(query[:price]).by_food(query[:food])
    else
      @restaurants = current_user.my_friends_restaurants
    end


    @markers = Gmaps4rails.build_markers(@restaurants) do |restaurant, marker|
      marker.lat restaurant.latitude
      marker.lng restaurant.longitude
      marker.infowindow render_to_string(partial: "map_box", locals: { restaurant: restaurant })
    end
  end
end