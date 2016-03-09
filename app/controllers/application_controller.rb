class ApplicationController < ActionController::Base
  include PublicActivity::StoreController
  before_action :authenticate_user!, unless: :pages_or_subscribers_controller?
  before_action :count_notifs
  before_action :tracking

  # on laisse unless pages_controller au cas ou pour l'instant
  # include Pundit

  protect_from_forgery with: :exception
  before_filter :configure_permitted_parameters, if: :devise_controller?

  # after_action :verify_authorized, except:  :index, unless: :devise_or_pages_controller?
  # after_action :verify_policy_scoped, only: :index, unless: :devise_or_pages_controller?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized


  protected

  def count_notifs
    if user_signed_in?
      activities = PublicActivity::Activity.where(owner_id: current_user.my_friends_ids, owner_type: 'User').order('created_at DESC').limit(20)
      @notification_count = activities.where(read: false).first == nil ? 0 : activities.where(read: false).count
    end
  end

  def split_friends_by_categories

    @category_1 = []
    @category_2 = []
    @category_3 = []

    # marge minime d'amélioration: ne pas prendre en compte les invisible friends dans ces catégories (car non affiché)
    TasteCorrespondence.where("member_one_id = ? or member_two_id = ?", @user.id, @user.id).each do |correspondence|

      member_one_id = correspondence.member_one_id
      member_two_id = correspondence.member_two_id
      if member_one_id == @user.id
        case correspondence.category
          when 1
            @category_1 << member_two_id
          when 2
            @category_2 << member_two_id
          when 3
            @category_3 << member_two_id
        end

      elsif member_two_id == @user.id
        case correspondence.category
          when 1
            @category_1 << member_one_id
          when 2
            @category_2 << member_one_id
          when 3
            @category_3 << member_one_id
        end
      end

    end

  end

  def fetch_experts_info(experts_ids)

    experts = User.where(id: experts_ids)

    @experts_recommendations = {}
    @experts_public_recommendations = {}
    Recommendation.where(user_id: experts_ids).each do |recommendation|
        @experts_recommendations[recommendation.user_id] ||= []
        @experts_recommendations[recommendation.user_id] << recommendation.restaurant_id
      if recommendation.public == true
        @experts_public_recommendations[recommendation.user_id] ||= []
        @experts_public_recommendations[recommendation.user_id] << recommendation.restaurant_id
      end
    end

    @experts_wishes = {}
    Wish.where(user_id: experts_ids).each do |wish|
      @experts_wishes[wish.user_id] ||= []
      @experts_wishes[wish.user_id] << wish.restaurant_id
    end

    @experts_followers = {}
    Followership.where(following_id: experts_ids).each do |followership|
      @experts_followers[followership.following_id] ||= []
      @experts_followers[followership.following_id] << followership.follower_id
    end

    @experts_followings = {}
    Followership.where(follower_id: experts_ids).each do |followership|
      @experts_followers[followership.follower_id] ||= []
      @experts_followers[followership.follower_id] << followership.following_id
    end

    @mutual_restaurants = {}
    experts.each do |expert|
      @mutual_restaurants[expert.id] = Restaurant.joins(:recommendations).where(recommendations: {user_id: expert.id, public: true}).pluck(:id) & @user.my_restaurants_ids
    end

  end

  def identify_or_create_restaurant

    # Si c'est une nouvelle recommandation on check que la personne a bien choisi un resto parmis la liste et on identifie ou crée le restaurant via la fonction
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

  def create_restaurant_from_foursquare
    client = Foursquare2::Client.new(
      api_version:    ENV['FOURSQUARE_API_VERSION'],
      client_id:      ENV['FOURSQUARE_CLIENT_ID'],
      client_secret:  ENV['FOURSQUARE_CLIENT_SECRET']
    )

    search = client.venue(@restaurant_id)
    restaurant = Restaurant.where(name: @restaurant_name).first_or_initialize(
      name:               search.name,
      address:            "#{search.location.address}",
      city:               "#{search.location.city}",
      postal_code:        "#{search.location.postalCode}",
      full_address:       "#{search.location.address}, #{search.location.city} #{search.location.postalCode}",
      food:               Food.where(name: search.categories[0].shortName).first_or_create,
      latitude:           search.location.lat,
      longitude:          search.location.lng,
      price_range:        search.attributes.groups[0] ? search.attributes.groups[0].items[0].priceTier  : nil,
      picture_url:        search.photos.groups[0] ? "#{search.photos.groups[0].items[0].prefix}1000x1000#{search.photos.groups[0].items[0].suffix}" : "http://needl.s3.amazonaws.com/production/restaurant_pictures/pictures/000/restaurant%20default.jpg",
      phone_number:       search.contact.phone ? search.contact.phone : nil,
      foursquare_id:      @restaurant_id,
      foursquare_rating:  search.rating
    )

    # pour rendre plus vite dans l'api
    restaurant.food_name = Food.find(restaurant.food_id).name

    if restaurant.save
      link_to_subways(restaurant)
      # pour créer le RestaurantType correspondant
      restaurant.attribute_category_from_food
      return restaurant
    else
      flash[:alert] = "Nous ne parvenons pas à trouver ce restaurant"
      return redirect_to new_api_recommendation_path(query: @query, :user_email => params["user_email"], :user_token => params["user_token"])
    end
  end

  def link_to_subways(restaurant)
    client = GooglePlaces::Client.new(ENV['GOOGLE_API_KEY'])
    # stations erronnées reconnaissables à leur nom
    false_subway_stations_by_name = [
      "Elysees Metro Hub", "Métro invalides",
      "Metro Saint-Paul",
      "Metro Station Anvers",
      "Métro Saint Germain des Près",
      "Paris train station",
      "Station de Métro Les Halles",
      "Paris Est"]

      false_subway_stations_by_coordinates = [
        [48.870871, 2.332217],
        [48.876305, 2.333199],
        [48.831483, 2.355692],
        [48.869644, 2.336445],
        [48.853387, 2.343706],
        [48.867531, 2.313542],
        [48.882598, 2.309639],
        [48.865299, 2.374381],
        [48.861272, 2.374214]]


    search_less_than_500_meters = client.spots(restaurant.latitude, restaurant.longitude, :radius => 500, :types => 'subway_station')

    # on enleve toutes les stations erronees

    search_less_than_500_meters.delete_if { |result| false_subway_stations_by_name.include?(result.name)}
    search_less_than_500_meters.delete_if do|result|
      coordinates_result = [result.lat, result.lng]
      false_subway_stations_by_coordinates.include?(coordinates_result)
    end

    # recherche du plus près au cas où il n'y en ait pas dans les 500m

    search_by_closest = client.spots(restaurant.latitude, restaurant.longitude, :rankby => 'distance', :types => 'subway_station')[0..5]

    # on enlève toutes les stations erronées
    search_by_closest.delete_if { |result| false_subway_stations_by_name.include?(result.name)}
    search_by_closest.delete_if do|result|
      coordinates_result = [result.lat, result.lng]
      false_subway_stations_by_coordinates.include?(coordinates_result)
    end
    search_by_closest = search_by_closest.first
    # on récupère le tout

    search = search_less_than_500_meters.length > 0 ? search_less_than_500_meters : [search_by_closest]

    # on associe chaque station de metro au restaurant

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
    # enregistrer les subways dans la base de données restos pour rendre plus rapidement l'api
    restaurant.subway_id = restaurant.closest_subway_id
    restaurant.subway_name = Subway.find(restaurant.subway_id).name
    array = []
    restaurant.subways.each do |subway|
      array << {subway.id => subway.name}
    end
    restaurant.subways_near = array

    restaurant.save

  end

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

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:account_update) << :name
  end

  def after_sign_in_path_for(resource_or_scope)
    restaurants_path
  end

  def after_sign_out_path_for(resource_or_scope)
    restaurants_path
  end

  private

  def devise_or_pages_controller?
    devise_controller? || pages_controller?
  end

  def pages_or_subscribers_controller?
    controller_name == "pages" || controller_name == "subscribers"  # Brought by the `high_voltage` gem
  end

  def user_not_authorized
    flash[:error] = I18n.t('controllers.application.user_not_authorized', default: "You can't access this page.")
    redirect_to(root_path)
  end

  def tracking
    @tracker = Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])
  end

  def unthank_friends(friends_to_unthank_ids)

    friends_to_unthank_ids.each do |friend_id|
      # on leur fait perdre à chacun un point d'expertise
      friend = User.find(friend_id)
      friend.score -= 1
      friend.save
      @tracker.track(@user.id, 'Unthanks', { "user" => @user.name, "User Type" => "Friend"})
    end

  end

  def unthank_experts(experts_to_unthank_ids)

    experts_to_unthank_ids.each do |expert_id|
      # on leur fait perdre à chacun un point d'expertise
      expert = User.find(expert_id)
      expert.public_score -= 1
      expert.save
      @tracker.track(@user.id, 'Unthanks', { "user" => @user.name, "User Type" => "Expert"})
    end

  end

end
