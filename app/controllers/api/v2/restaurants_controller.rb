class Api::V2::RestaurantsController < ApplicationController

  acts_as_token_authentication_handler_for User
  skip_before_action :verify_authenticity_token
  skip_before_filter :authenticate_user!

  def show

    @restaurant = Restaurant.find(params["id"].to_i)
    @user = User.find_by(authentication_token: params["user_token"])
    @pictures = @restaurant.restaurant_pictures.first ? @restaurant.restaurant_pictures.map {|element| element.picture} : [@restaurant.picture_url]
    @tracker.track(@user.id, 'restaurant_page', { "user" => @user.name, "restaurant" => @restaurant.name })

    @all_friends_and_experts_recommending = []
    @all_friends_wishing = []
    @my_friends_ids = @user.my_visible_friends_ids
    @my_experts_ids = @user.followings.pluck(:id)
    if Rails.env.development? == true
      @my_experts_ids      = []
    end

    score_variables

    recommendations_i_trust.where(restaurant_id: @restaurant.id).each do |recommendation|
      @all_friends_and_experts_recommending << recommendation.user_id
      score_allocation_recommendations(recommendation)
    end

    Wish.where(restaurant_id: @restaurant.id, user_id: @my_friends_ids + [@user.id]).each do |wish|
      @all_friends_wishing << wish.user_id
      score_allocation_wishes(wish)
    end

  end

  def index

    @user                                 = User.find_by(authentication_token: params["user_token"])
    @my_friends_ids                       = @user.my_friends_ids
    @my_experts_ids                       = @user.followings.pluck(:id)
    if Rails.env.development? == true
      @my_experts_ids = []
    end
    restaurants_ids                       = @user.my_friends_restaurants_ids + @user.my_restaurants_ids + @user.my_experts_restaurants_ids
    @restaurants                          = Restaurant.where(id: restaurants_ids.uniq)

    wishes                                = Wish.where(user_id: @my_friends_ids + [@user.id])
    restaurant_pictures                   = RestaurantPicture.where(restaurant_id: restaurants_ids)
    restaurant_subways                    = RestaurantSubway.where(restaurant_id: restaurants_ids)
    restaurant_types                      = RestaurantType.where(restaurant_id: restaurants_ids)
    # elements de l'algorithme du score

    score_variables
    fetch_restaurants_infos(wishes, restaurant_pictures, restaurant_types)


  end

  def autocomplete
    @query = params[:query]

    @restaurants = search_via_database
    @restaurants += search_via_foursquare

    @restaurants.uniq! { |restaurant| [ restaurant[:name], restaurant[:address] ] }
    @restaurants.take(7)
  end

  def user_updated
    @user                         = User.find_by(authentication_token: params["user_token"])
    friend_or_expert_id           = params["user_id"]
    friend_or_expert              = User.find(friend_or_expert_id)
    restaurants_ids               = []
    if @user.followings.include?(friend_or_expert_id)
      restaurants_ids             = Restaurant.joins(:recommendations).where(recommendations: {user_id: friend_or_expert_id, public: true})
    else
      restaurants_ids             = friend_or_expert.my_restaurants_ids
    end
    @restaurants                  = Restaurant.where(id: restaurants_ids)
    @my_friends_ids               = @user.my_friends_ids
    @my_experts_ids               = @user.followings.pluck(:id)
    wishes                        = Wish.where(user_id: @my_friends_ids + [@user.id])
    restaurant_pictures           = RestaurantPicture.where(restaurant_id: restaurants_ids)
    restaurant_subways            = RestaurantSubway.where(restaurant_id: restaurants_ids)
    restaurant_types              = RestaurantType.where(restaurant_id: restaurants_ids)

    score_variables
    fetch_restaurants_infos(wishes, restaurant_pictures, restaurant_types)

  end

  def add_pictures
    user          = User.find_by(authentication_token: params["user_token"])
    restaurant_id  = params["id"]
    # passer en public fin du test
    if user.public == false
      pictures = params["pictures"]
      pictures.each do |picture|
        RestaurantPicture.create(picture: picture, restaurant_id: restaurant_id)
      end
    end
  end

  private

  def search_via_database

    useless_words = ["le", "la", "à", "a", "chez", "du", "restaurant", "cafe", "café", "bar"]
    query_terms = []
    if @query.split.collect { |name| "%#{name}%" }.delete_if{|name| useless_words.include?(name.gsub("%","").downcase)} != []
      query_terms = @query.split.collect { |name| "%#{name}%" }.delete_if{|name| useless_words.include?(name.gsub("%","").downcase)}
    else
      query_terms = @query.split.collect { |name| "%#{name}%" }
    end
    restaurants_table = Restaurant.arel_table
    restaurant_ids = Restaurant.where(restaurants_table[:name].matches_all(query_terms)).pluck(:id)
    restaurant_ids += Restaurant.where(restaurants_table[:name].matches_any(query_terms)).pluck(:id)
    restaurant_ids.uniq!
    order = "position(id::text in '#{restaurant_ids.join(',')}')"
    restaurants = Restaurant.where(id: restaurant_ids).order(order)

    restaurants = restaurants.map do |restaurant|
      { origin: 'db', name: restaurant.name, address: restaurant.address, id: restaurant.id, name_and_address: "#{restaurant.name}: #{restaurant.address}, #{restaurant.city} #{customize_postal_code(restaurant.postal_code)}" }
    end

    if restaurants.length >= 6
      restaurants = restaurants.take(5)
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
    if postal_code != "" && postal_code != nil
      if postal_code[3] == "0"
        return postal_code[4] + "ᵉ"
      else
        return postal_code[3] + postal_code[4] + "ᵉ"
      end
    else
      return ""
    end
  end




end
