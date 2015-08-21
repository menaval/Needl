module Api
  class RestaurantsController < ApplicationController
    acts_as_token_authentication_handler_for User
    skip_before_action :verify_authenticity_token
    skip_before_filter :authenticate_user!

    def show
      @restaurant = Restaurant.find(params["id"].to_i)
      @user = User.find_by(authentication_token: params["user_token"])
      @picture = @restaurant.restaurant_pictures.first ? @restaurant.restaurant_pictures.first.picture : @restaurant.picture_url
      @pictures = @restaurant.restaurant_pictures.first ? @restaurant.restaurant_pictures.map {|element| element.picture} : [@restaurant.picture_url]
      # @subway = Subway.find(@restaurant.closest_subway_id)
      @friends_wishing = @restaurant.friends_wishing_this_restaurant(@user)
    end

    def index
      @user         = User.find_by(authentication_token: params["user_token"])
      restaurants_ids  = @user.my_friends_restaurants_ids + @user.my_restaurants_ids
      @restaurants = Restaurant.where(id: restaurants_ids)
      query         = params[:query]
      my_visible_friends_and_me = @user.my_visible_friends_ids_and_me
      @recommendations = Recommendation.where(user_id: my_visible_friends_and_me)
      @wishes = Wish.where(user_id: my_visible_friends_and_me)

      # associer les ambiances et amis recommandant aux restaurants avec une seule requête
      @all_ambiences = {}
      @all_friends_recommending = {}
      @recommendations.each do |recommendation|
        @all_ambiences[recommendation.restaurant_id] ||= []
        @all_ambiences[recommendation.restaurant_id] << recommendation.ambiences
        @all_friends_recommending[recommendation.restaurant_id] ||= []
        @all_friends_recommending[recommendation.restaurant_id] << recommendation.user_id
      end

      @all_friends_wishing = {}
      @wishes.each do |wish|
        @all_friends_wishing[wish.restaurant_id] ||= []
        @all_friends_wishing[wish.restaurant_id] << wish.user_id
      end

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

      useless_words = ["le", "la", "à", "a", "chez", "du", "restaurant", "cafe", "café", "bar"]
      query_terms = @query.split.collect { |name| "%#{name}%" }.delete_if{|name| useless_words.include?(name.gsub("%","").downcase)}
      restaurants_table = Restaurant.arel_table
      restaurants = Restaurant.where(restaurants_table[:name].matches_any(query_terms))

      restaurants = restaurants.map do |restaurant|
        { origin: 'db', name: restaurant.name, address: restaurant.address, id: restaurant.id, name_and_address: "#{restaurant.name}: #{restaurant.address}, #{restaurant.city} #{customize_postal_code(restaurant.postal_code)}" }
      end

      if restaurants.length >= 4
        restaurants = restaurants.take(3)
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
        categoryId: "#{ENV['FOURSQUARE_FOOD_CATEGORY']},#{ENV['FOURSQUARE_BAR_CATEGORY']}",
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
