class RecommendationsController < ApplicationController
  include PublicActivity::StoreController
  before_action :load_activities, only: [:index, :new, :edit]

  def index
    @recommendations = Recommendation.all
    @friendships = current_user.friendships_by_status
    read_all_notification
  end

  def new
    @recommendation = Recommendation.new
  end

  def create
    @recommendation = current_user.recommendations.new(recommendation_params)

    if Recommendation.where(restaurant_id: @recommendation.restaurant_id, user_id: @recommendation.user_id).any?
      update

    elsif find_restaurant_by_origin != nil
      find_restaurant_by_origin

      @recommendation.restaurant = @restaurant
      if @recommendation.save
        find_restaurant_by_origin
        @recommendation.restaurant.recompute_price(@recommendation)
        redirect_to restaurant_path(@recommendation.restaurant)
      else
        redirect_to new_recommendation_path, notice: "Les ambiences, points forts ou le prix n'ont pas été remplis"
      end

    else
      redirect_to new_recommendation_path, notice: "Nous n'avons pas retrouvé votre restaurant, choisissez parmis la liste qui vous est proposée"
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
      name:         search.name,
      address:      "#{search.location.address}, #{search.location.city}",
      food:         Food.where(name: search.categories[0].shortName).first_or_create,
      latitude:     search.location.lat,
      longitude:    search.location.lng,
      picture_url:  search.photos ? "#{search.photos.groups[0].items[0].prefix}1000x1000#{search.photos.groups[0].items[0].suffix}" : "restaurant_default.jpg",
      phone_number: search.contact.phone ? search.contact.phone : nil
    )

    if restaurant.save
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
    params.require(:recommendation).permit(:price, :review, { strengths: [] }, { ambiences: [] })
  end

  def load_activities
    @activities = PublicActivity::Activity.where(owner_id: current_user.my_friends.map(&:id), owner_type: 'User').order('created_at DESC').limit(20)
  end

  def update
    @recommendation.update_attributes(recommendation_params)
    @recommendation.restaurant.recompute_price(@recommendation)
    redirect_to restaurant_path(@recommendation.restaurant)
  end

  def read_all_notification
    PublicActivity::Activity.where(owner_id: current_user.my_friends.map(&:id), owner_type: 'User').each do |activity|
      activity.read = true
      activity.save
    end
  end
end
