module Api
  class RestaurantsController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_before_filter :authenticate_user!

    def index
      @query = params[:query]

      @restaurants = search_via_database

@restaurants = []
      @restaurants += search_via_foursquare

      @restaurants.uniq! { |restaurant| restaurant[:name] }
      @restaurants.take(20)
    end

    private

    def search_via_database
      restaurants = Restaurant.where("name ilike ?", "%#{@query}%").limit(20)

      restaurants = restaurants.map do |restaurant|
        { origin: 'db', name: restaurant.name, id: restaurant.id }
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
        { origin: 'foursquare', name: restaurant['name'], id: restaurant['id'] }
      end

      return restaurants
    end
  end
end
