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

    @user                                = User.find_by(authentication_token: params["user_token"])
    @my_friends_ids                       = @user.my_friends_ids
    @my_experts_ids                       = @user.followings.pluck(:id)
    if Rails.env.development? == true
      @my_experts_ids = []
    end
    restaurants_ids                            = @user.my_friends_restaurants_ids + @user.my_restaurants_ids + @user.my_experts_restaurants_ids
    @restaurants                               = Restaurant.where(id: restaurants_ids.uniq)

    wishes                                     = Wish.where(user_id: @my_friends_ids + [@user.id])
    restaurant_pictures                        = RestaurantPicture.where(restaurant_id: restaurants_ids)
    restaurant_subways                         = RestaurantSubway.where(restaurant_id: restaurants_ids)
    restaurant_types                           = RestaurantType.where(restaurant_id: restaurants_ids)
    # elements de l'algorithme du score

    score_variables

    # associer les ambiances, occasions et amis recommandant aux restaurants avec une seule requête. De même pour récupérer dans chacun des restaurants quels sont les amis qui recommandent
    @all_ambiences = {}
    @all_strengths = {}
    @all_occasions = {}
    @all_friends_and_experts_recommending = {}

    recommendations_i_trust.each do |recommendation|
      @all_ambiences[recommendation.restaurant_id] ||= []
      @all_ambiences[recommendation.restaurant_id] << recommendation.strengths
      @all_strengths[recommendation.restaurant_id] ||= []
      @all_strengths[recommendation.restaurant_id] << recommendation.strengths
      @all_occasions[recommendation.restaurant_id] ||= []
      if recommendation.occasions
        @all_occasions[recommendation.restaurant_id] << recommendation.occasions
      end
      @all_friends_and_experts_recommending[recommendation.restaurant_id] ||= []
      @all_friends_and_experts_recommending[recommendation.restaurant_id] << recommendation.user_id
      score_allocation_recommendations(recommendation)
    end

    # récupérer en une seule requête tous les amis qui ont wishlisté les restaurants

    @all_friends_wishing   = {}
    wishes.each do |wish|
      @all_friends_wishing[wish.restaurant_id] ||= []
      @all_friends_wishing[wish.restaurant_id] << wish.user_id
      score_allocation_wishes(wish)
    end


    @all_pictures = {}
    restaurant_pictures.each do |restaurant_picture|
      @all_pictures[restaurant_picture.restaurant_id] ||= []
      @all_pictures[restaurant_picture.restaurant_id] << restaurant_picture.picture
    end

    @all_types = {}
    restaurant_types.each do |restaurant_type|
      @all_types[restaurant_type.restaurant_id] ||= []
      @all_types[restaurant_type.restaurant_id] << restaurant_type.type_id
    end

  end

  def autocomplete
    @query = params[:query]

    @restaurants = search_via_database
    @restaurants += search_via_foursquare

    @restaurants.uniq! { |restaurant| [ restaurant[:name], restaurant[:address] ] }
    @restaurants.take(7)
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

  def recommendations_i_trust
    t = Recommendation.arel_table
    if @my_experts_ids != []
      Recommendation.where(t[:user_id].eq_any(@my_friends_ids + [@user.id]).or(t[:user_id].eq_any(@my_experts_ids).and(t[:public].eq(true))))
    else
      Recommendation.where(t[:user_id].eq_any(@my_friends_ids + [@user.id]))
    end
  end

  def score_variables

    score_coefficients
    split_friends_by_categories

    @all_friends_category_1_recommending = {}
    @all_friends_category_2_recommending = {}
    @all_friends_category_3_recommending = {}
    @all_experts_recommending = {}
    @all_friends_category_1_wishing = {}
    @all_friends_category_2_wishing = {}
    @all_friends_category_3_wishing = {}

  end

  def score_allocation_recommendations(recommendation)

    if @category_1.include?(recommendation.user_id)
      @all_friends_category_1_recommending[recommendation.restaurant_id] ||= []
      @all_friends_category_1_recommending[recommendation.restaurant_id] << recommendation.user_id
    elsif @category_2.include?(recommendation.user_id)
      @all_friends_category_2_recommending[recommendation.restaurant_id] ||= []
      @all_friends_category_2_recommending[recommendation.restaurant_id] << recommendation.user_id
    elsif @category_3.include?(recommendation.user_id)
      @all_friends_category_3_recommending[recommendation.restaurant_id] ||= []
      @all_friends_category_3_recommending[recommendation.restaurant_id] << recommendation.user_id
    elsif @my_experts_ids.include?(recommendation.user_id)
      @all_experts_recommending[recommendation.restaurant_id] ||= []
      @all_experts_recommending[recommendation.restaurant_id] << recommendation.user_id
    end

  end


  def score_allocation_wishes(wish)

    if @category_1.include?(wish.user_id)
      @all_friends_category_1_wishing[wish.restaurant_id] ||= []
      @all_friends_category_1_wishing[wish.restaurant_id] << wish.user_id
    elsif @category_2.include?(wish.user_id)
      @all_friends_category_2_wishing[wish.restaurant_id] ||= []
      @all_friends_category_2_wishing[wish.restaurant_id] << wish.user_id
    elsif @category_3.include?(wish.user_id)
      @all_friends_category_3_wishing[wish.restaurant_id] ||= []
      @all_friends_category_3_wishing[wish.restaurant_id] << wish.user_id
    end

  end


  def score_coefficients

    @recommendation_coefficient_category_1   = 15
    @recommendation_coefficient_category_2   = 16
    @recommendation_coefficient_category_3   = 17
    @recommendation_coefficient_expert       = 14
    @wish_coefficient_category_1             = 7
    @wish_coefficient_category_2             = 8
    @wish_coefficient_category_3             = 9
    @me_recommending_coefficient             = 6
    @me_wishing_coefficient                  = 10

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
