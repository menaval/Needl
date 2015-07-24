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

    is_a_wish = params[:recommendation][:wish]
    if is_a_wish == "true"
      create_a_wish
    else
      # si l'utilisateur a déà recommandé cet endroit alors on actualise sa reco
      if Recommendation.where(restaurant_id:params["restaurant_id"].to_i, user_id: current_user.id).any?
        update

      # Si c'est une nouvelle recommandation on check que la personne a bien choisi un resto parmis la liste et on identifie ou crée le restaurant via la fonction
      elsif identify_or_create_restaurant != nil

        # On crée la recommandation à partir des infos récupérées
        @recommendation = current_user.recommendations.new(recommendation_params)
        @recommendation.restaurant = @restaurant

        #  si les informations récupérées ont bien toutes été remplies on enregistre la reco, update le prix du resto et on le track
        if @recommendation.save

          @recommendation.restaurant.update_price_range(@recommendation.price_ranges.first)
          @tracker.track(current_user.id, 'New Reco', { "restaurant" => @restaurant.name, "user" => current_user.name })

          # si c'était sur ma liste de wish ça l'enlève
          if Wish.where(restaurant_id:params["restaurant_id"].to_i, user_id: current_user.id).any?
            Wish.where(restaurant_id:params["restaurant_id"].to_i, user_id: current_user.id).first.destroy
          end

          # si première recommandation ou wish, alors page d'accueil du profil ceo
          if current_user.recommendations.count == 1 && current_user.wishes.count == 0
            Friendship.create(sender_id: 125, receiver_id: current_user.id, accepted: true)
            redirect_to welcome_ceo_users_path

          #sinon on renvoie à la page du resto
          else
            redirect_to restaurant_path(@recommendation.restaurant)
          end

        # si certaines infos nécessaires n'ont pas été remplies
        else
          redirect_to new_recommendation_path, notice: "Les ambiances, points forts ou le prix n'ont pas été remplis"
        end

      # Si le restaurant n'a pas été pioché dans la liste, on le redirige sur la même page
      else
        redirect_to new_recommendation_path, notice: "Nous n'avons pas retrouvé votre restaurant, choisissez parmi la liste qui vous est proposée"
      end
    end
  end

  def destroy
    reco = Recommendation.find(params[:id])
    reco.destroy
    redirect_to root_path, notice: 'Le restaurant a bien été retiré de vos recommandations'
  end

  private

  def identify_or_create_restaurant

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
      name:         search.name,
      address:      "#{search.location.address}",
      city:         "#{search.location.city}",
      postal_code:  "#{search.location.postalCode}",
      full_address: "#{search.location.address}, #{search.location.city} #{search.location.postalCode}",
      food:         Food.where(name: search.categories[0].shortName).first_or_create,
      latitude:     search.location.lat,
      longitude:    search.location.lng,
      picture_url:  search.photos.groups[0] ? "#{search.photos.groups[0].items[0].prefix}1000x1000#{search.photos.groups[0].items[0].suffix}" : "restaurant_default.jpg",
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

  def create_a_wish
    # si l'utilisateur a déjà mis sur sa liste de souhaits cet endroit (sachant que ça peut être fait depuis 2 endroits) alors on le lui dit
    if Wish.where(restaurant_id:params["restaurant_id"].to_i, user_id: current_user.id).any?
      redirect_to restaurants_path, notice: "Restaurant déjà sur ta wishlist"

    # Si c'est une nouvelle whish on check que la personne a bien choisi un resto parmis la liste et on identifie ou crée le restaurant via la fonction
    elsif identify_or_create_restaurant != nil

      # On vérifie qu'il n'a pas déjà recommandé l'endroit, sinon pas de raison de le mettre dans les restos à tester
      if Recommendation.where(restaurant_id:params["restaurant_id"].to_i, user_id: current_user.id).length > 0
        redirect_to restaurants_path, notice: "Cette adresse fait déjà partie des restaurants que vous recommandez"
      else
        # On crée la recommandation à partir des infos récupérées et on track
        @wish = Wish.create(user_id: current_user.id, restaurant_id: @restaurant.id)
        # @wish.restaurant = @restaurant

        @tracker.track(current_user.id, 'New Wish', { "restaurant" => @restaurant.name, "user" => current_user.name })

        # si première wish ou reco, alors page d'accueil du profil ceo
        if current_user.wishes.count == 1 && current_user.recommendations.count == 0
          Friendship.create(sender_id: 125, receiver_id: current_user.id, accepted: true)
          redirect_to welcome_ceo_users_path

        #sinon on renvoie à la page du resto
        else
          redirect_to restaurant_path(@wish.restaurant)
        end
      end

    # Si le restaurant n'a pas été pioché dans la liste, on le redirige sur la même page
    else
      redirect_to new_recommendation_path, notice: "Nous n'avons pas retrouvé votre restaurant, choisissez parmi la liste qui vous est proposée"
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
    search_by_closest.delete_if { |result| !false_subway_stations_by_name.include?(result.name)}
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

  def recommendation_params
    params.require(:recommendation).permit(:review, :wish, { strengths: [] }, { ambiences: [] }, { price_ranges: [] })
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
