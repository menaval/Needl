class RestaurantsController < ApplicationController
  def show
    @restaurant = Restaurant.find(params[:id])
    @picture = @restaurant.restaurant_pictures.first ? @restaurant.restaurant_pictures.first.picture : @restaurant.picture_url
    @pictures = @restaurant.restaurant_pictures.first ? @restaurant.restaurant_pictures.map {|element| element.picture} : [@restaurant.picture_url]
    @subway = Subway.find(@restaurant.closest_subway_id)
  end

  def map_box
    @restaurant = Restaurant.find(params[:id])
    render layout: false
  end

  def index
    query         = params[:query]
    @restaurants  = current_user.my_friends_restaurants

    if query
      if @restaurants.by_price_range(query[:price_range]).by_food(query[:food]).by_friend(query[:friend]).by_subway(query[:subway]).count > 0
        @restaurants = @restaurants.by_price_range(query[:price_range]).by_food(query[:food]).by_friend(query[:friend]).by_subway(query[:subway])
      else
        flash[:notice] = "Aucun restaurant pour cette recherche"
      end
    else
      if current_user.recommendations.count == 0
        redirect_to new_recommendation_path, notice: "Partages ta première reco avant de découvrir celles de tes amis !"
      end
    end

    @markers = Gmaps4rails.build_markers(@restaurants) do |restaurant, marker|
      marker.lat restaurant.latitude
      marker.lng restaurant.longitude
      marker.json(restaurant_id: restaurant.id)
      # marker.picture({
      #             :url => ActionController::Base.helpers.asset_path("quote-end.png"),
      #             :width   => 25,
      #             :height  => 25,
      #             # :shadow_picture
      #             # :shadow_width
      #             # :shadow_height
      #            })
    end
  end
end