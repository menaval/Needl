class RecommendationsController < ApplicationController
  include PublicActivity::StoreController
  before_action :load_activities, only: [:index]

  def index
    @recommendations = Recommendation.all
    read_all_notification
  end

  def new
    @recommendation = Recommendation.new
  end

  def create

    if Recommendation.where(restaurant_id:params["restaurant_id"].to_i, user_id: current_user.id).any?
      update
    elsif find_restaurant_by_origin != nil
      @recommendation = current_user.recommendations.new(recommendation_params)
      @recommendation.restaurant = @restaurant
      if @recommendation.save
        if @restaurant_origin == "foursquare" && @recommendation.price
          @recommendation.restaurant.update_price_range(@recommendation.price_ranges.first)
        end
        @tracker.track(current_user.id, 'New Reco', { "restaurant" => @restaurant.name, "user" => current_user.name })
        redirect_to restaurant_path(@recommendation.restaurant)
      else
        redirect_to new_recommendation_path, notice: "Les ambiances, points forts ou le prix n'ont pas été remplis"
      end

    else
      redirect_to new_recommendation_path, notice: "Nous n'avons pas retrouvé votre restaurant, choisissez parmi la liste qui vous est proposée"
    end
  end

  private

  def create_new_subway(result)
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
    return subway
  end

  def link_to_subways(restaurant)
    client = GooglePlaces::Client.new(ENV['GOOGLE_API_KEY'])
    search_less_than_500_meters = client.spots(restaurant.latitude, restaurant.longitude, :radius => 500, :types => 'subway_station')
    search_by_closest = client.spots(restaurant.latitude, restaurant.longitude, :rankby => 'distance', :types => 'subway_station').first
    search = search_less_than_500_meters.length > 0 ? search_less_than_500_meters : [search_by_closest]

    search.each do |result|
      if Subway.find_by(latitude: result.lat) == nil
        subway = create_new_subway(result)
      else
        subway = Subway.find_by(latitude: result.lat)
      end
      restaurant_subway = RestaurantSubway.create(
        restaurant_id: restaurant.id,
        subway_id:     subway.id
        )
    end
  end

  def create_restaurant_from_foursquare
    client = Foursquare2::Client.new(
      api_version:    ENV['FOURSQUARE_API_VERSION'],
      client_id:      ENV['FOURSQUARE_CLIENT_ID'],
      client_secret:  ENV['FOURSQUARE_CLIENT_SECRET']
    )

    search = client.venue(@restaurant_id)
    restaurant = Restaurant.where(name: @restaurant_name).first_or_initialize(
      name:         search.name,
      address:      "#{search.location.address}, #{search.location.city}",
      food:         Food.where(name: search.categories[0].shortName).first_or_create,
      latitude:     search.location.lat,
      longitude:    search.location.lng,
      picture_url:  search.photos ? "#{search.photos.groups[0].items[0].prefix}1000x1000#{search.photos.groups[0].items[0].suffix}" : "restaurant_default.jpg",
      phone_number: search.contact.phone ? search.contact.phone : nil
    )

    if restaurant.save
      link_to_subways(restaurant)
      return restaurant
    else
      flash[:alert] = "Nous ne parvenons pas à trouver ce restaurant"
      return redirect_to new_recommendation_path(query: @query)
    end
  end

  def find_restaurant_by_origin

    if  params[:restaurant_origin] == "db" || params[:restaurant_origin] == "foursquare"

      @restaurant_id      = params[:restaurant_id]
      @restaurant_name    = params[:restaurant_name]
      @restaurant_origin  = params[:restaurant_origin]

      if @restaurant_origin == "foursquare"
        @restaurant = create_restaurant_from_foursquare
      else
        @restaurant = Restaurant.find(@restaurant_id)
      end

    else
      nil
    end

  end

  def recommendation_params
    params.require(:recommendation).permit(:price, :review, { strengths: [] }, { ambiences: [] }, { price_ranges: [] })
  end

  def load_activities
    @activities = PublicActivity::Activity.where(owner_id: current_user.my_friends_ids, owner_type: 'User').order('created_at DESC').limit(20)
  end

  def update
    recommendation = Recommendation.where(restaurant_id:params["restaurant_id"].to_i, user_id: current_user.id).first
    recommendation.update_attributes(recommendation_params)
    redirect_to restaurant_path(recommendation.restaurant)
  end

  def read_all_notification
    PublicActivity::Activity.where(owner_id: current_user.my_friends_ids, owner_type: 'User').each do |activity|
      activity.read = true
      activity.save
    end
  end
end
