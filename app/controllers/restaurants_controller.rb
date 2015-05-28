class RestaurantsController < ApplicationController
  def show
    @restaurant = Restaurant.find(params[:id])
    @picture = @restaurant.restaurant_pictures.first ? @restaurant.restaurant_pictures.first.picture : @restaurant.picture_url
    @pictures = @restaurant.restaurant_pictures.first ? @restaurant.restaurant_pictures.map {|element| element.picture} : [@restaurant.picture_url]



    client = GooglePlaces::Client.new(ENV['GOOGLE_API_KEY'])
    search_less_than_500_meters = client.spots(@restaurant.latitude, @restaurant.longitude, :radius => 500, :types => 'subway_station')
    search_by_closest = client.spots(@restaurant.latitude, @restaurant.longitude, :rankby => 'distance', :types => 'subway_station').first
    search = search_less_than_500_meters.length > 0 ? search_less_than_500_meters : [search_by_closest]

    search.each do |result|
      if Subway.find_by(latitude: result.lat) == nil
        subway = Subway.create(
          name:      result.name,
          latitude:  result.lat,
          longitude: result.lng
          )
        result = Geocoder.search("#{result.lat}, #{result.lng}").first.data["address_components"]
        result.each do |component|
          if component["types"].include?("locality")
            city = component["long_name"]
            subway.city = city
            subway.save
          end
        end
      else
        subway = Subway.find_by(latitude: result.lat)
      end
      restaurant_subway = RestaurantSubway.create(
        restaurant_id: @restaurant.id,
        subway_id:     subway.id
        )
    end

  end

  def index
    query         = params[:query]
    @restaurants  = current_user.my_friends_restaurants

    if query
      if @restaurants.cheaper_than(query[:price]).by_food(query[:food]).by_friend(query[:friend]).count > 0
        @restaurants = @restaurants.cheaper_than(query[:price]).by_food(query[:food]).by_friend(query[:friend])
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
      marker.infowindow render_to_string(partial: "map_box", locals: { restaurant: restaurant })
    end
  end
end