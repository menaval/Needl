module Api
  class RestaurantsController < ApplicationController
    acts_as_token_authentication_handler_for User
    skip_before_action :verify_authenticity_token
    skip_before_filter :authenticate_user!

    def show
      @restaurant = Restaurant.find(params["id"].to_i)
      @user = User.find_by(authentication_token: params["user_token"])
      @picture = @restaurant.restaurant_pictures.first ? @restaurant.restaurant_pictures.first.picture : @restaurant.picture_url
    end

    def index
      user = User.find_by(authentication_token: params["user_token"])
      @restaurants = user.my_friends_restaurants
    end

    def autocomplete
      @query = params[:query]

      @restaurants = search_via_database
      @restaurants += search_via_foursquare

      @restaurants.uniq! { |restaurant| [ restaurant[:name], restaurant[:address] ] }
      @restaurants.take(5)
    end

    private

    def search_via_database
      restaurants = Restaurant.where("name ilike ?", "%#{@query}%").limit(4)

      restaurants = restaurants.map do |restaurant|
        { origin: 'db', name: restaurant.name, address: restaurant.address, id: restaurant.id, name_and_address: "#{restaurant.name}: #{restaurant.address}, #{restaurant.city} #{customize_postal_code(restaurant.postal_code)}" }
      end

      return restaurants
    end

    def search_via_foursquare
      client = Foursquare2::Client.new(
        api_version:    ENV['FOURSQUARE_API_VERSION'],
        client_id:      ENV['FOURSQUARE_CLIENT_ID'],
        client_secret:  ENV['FOURSQUARE_CLIENT_SECRET']
      )

      search = client.search_venues(
        categoryId: ENV['FOURSQUARE_FOOD_CATEGORY'],
        intent:     'browse',
        near:       'Paris',
        query:      @query
      )

      restaurants = search['venues'].map do |restaurant|
        { origin: 'foursquare', name: restaurant['name'], address: "#{restaurant.location.address}", id: restaurant['id'], name_and_address: "#{restaurant['name']}: #{restaurant.location.address}, #{restaurant.location.city} #{customize_postal_code(restaurant.location.postalCode)}" }
      end

      return restaurants
    end

    def customize_postal_code(postal_code)
      if postal_code
        if postal_code[3] == "0"
          return postal_code[4] + "ᵉ"
        else
          return postal_code[3] + postal_code[4] + "ᵉ"
        end
      end
    end

  end
end
