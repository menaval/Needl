class RecommendationsController < ApplicationController
  include PublicActivity::StoreController
  before_action :load_activities, only: [:index, :new, :edit]
  before_action :find_restaurant_by_origin, only: :create

  def index
    @recommendations = Recommendation.all
    @friendships = current_user.friendships_by_status
  end

  def new
    @recommendation = Recommendation.new
  end

  def create
    @recommendation = current_user.recommendations.new(recommendation_params)
    @recommendation.restaurant = @restaurant

    if @recommendation.save
      @recommendation.restaurant.recompute_price(@recommendation)
      redirect_to restaurant_path(@recommendation.restaurant)
    else
      render 'new'
    end
  end

  private

  def create_restaurant_from_foursquare
    client = Foursquare2::Client.new(
      api_version:    ENV['FOURSQUARE_API_VERSION'],
      client_id:      ENV['FOURSQUARE_CLIENT_ID'],
      client_secret:  ENV['FOURSQUARE_CLIENT_SECRET']
    )

    search = client.venue(@restaurant_id)
    restaurant = Restaurant.where(name: @restaurant_name).first_or_initialize(
      name:         search['name'],
      address:      "#{search["location"]["address"]}, #{search["location"]["city"]}",
      food:         Food.where(name: search['categories'][0]["shortName"]).first_or_create,
      latitude:     search["location"]["lat"],
      longitude:    search["location"]["lng"],
      picture_url:  "#{search.photo.prefix}1000x500#{search.photo.suffix}"
      phone_number: search.contact.phone
    )

    if restaurant.save
      return restaurant
    else
      flash[:alert] = "Nous ne parvenons pas à trouver ce restaurant"
      return redirect_to new_recommendation_path(query: @query)
    end
  end

  def find_restaurant_by_origin
    @restaurant_id      = params[:restaurant_id]
    @restaurant_name    = params[:restaurant_name]
    @restaurant_origin  = params[:restaurant_origin]

    if @restaurant_origin == "foursquare"
      @restaurant = create_restaurant_from_foursquare
    else
      @restaurant = Restaurant.find(@restaurant_id)
    end
  end

  def recommendation_params
    params.require(:recommendation).permit(:price, :review, { strengths: [] }, { ambiences: [] })
  end

  def load_activities
    @activities = PublicActivity::Activity.where(owner_id: current_user.my_friends.map(&:id), owner_type: 'User').order('created_at DESC').limit(20)
  end

end
