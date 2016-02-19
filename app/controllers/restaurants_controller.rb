class RestaurantsController < ApplicationController
  def show
    @restaurant = Restaurant.find(params[:id])
    @pictures = @restaurant.restaurant_pictures.first ? @restaurant.restaurant_pictures.map {|element| element.picture} : [@restaurant.picture_url]
    @wish = Wish.new
    @friends_wishing = @restaurant.friends_wishing_this_restaurant(current_user)
    @number_of_friends_recommending = Recommendation.where(user_id: current_user.my_visible_friends_ids_and_me, restaurant_id: @restaurant.id).length
    @did_i_recommend = Recommendation.where(user_id: current_user.id, restaurant_id: @restaurant.id).length > 0
    @did_i_wish = Wish.where(user_id: current_user.id, restaurant_id: @restaurant.id).length > 0
  end

  def map_box
    @restaurant = Restaurant.find(params[:id])
    render layout: false
  end

  def index
    query         = params[:query]
    restaurants_ids  = current_user.my_visible_friends_restaurants_ids + current_user.my_restaurants_ids
    @restaurants = Restaurant.where(id: restaurants_ids)

    if query
      if @restaurants.by_price_range(query[:price_range]).by_food(query[:food]).by_friend(query[:friend]).by_subway(query[:subway]).by_ambience(query[:ambience], query[:user_id]).by_occasion(query[:occasion], query[:user_id]).count > 0
        @restaurants = @restaurants.by_price_range(query[:price_range]).by_food(query[:food]).by_friend(query[:friend]).by_subway(query[:subway]).by_ambience(query[:ambience], query[:user_id]).by_occasion(query[:occasion], query[:user_id])
      else
        flash[:notice] = "Aucun restaurant pour cette recherche"
      end
    else
      if current_user.recommendations.count == 0
        redirect_to new_recommendation_path, notice: "Partage ta première reco avant de découvrir celles de tes amis !"
      end
    end

    @markers = @restaurants.map {|restaurant| {lat: restaurant.latitude, lng: restaurant.longitude, restaurant_id: restaurant.id}}
  end

end