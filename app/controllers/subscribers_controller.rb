class SubscribersController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def create
    @gibbon = Gibbon::Request.new(api_key: ENV['MAILCHIMP_API_KEY'])
    @list_id = ENV['MAILCHIMP_LIST_ID_WAITING_ANDROID']

    @array = []
    @gibbon.lists(@list_id).members.retrieve["members"].each do |user|
      @array << user["email_address"]
    end

    if @array.include?(params["email"]) == false
      @gibbon.lists(@list_id).members.create(
        body: {
          email_address: params["email"],
          status: "subscribed"
        }
      )

    end
    redirect_to root_path(:subscribed => true)
  end

  def login
    delta_latitude = 0.0004
    delta_longitude = 0.0008

    url = request.referer

    url = 'http://716lavie.com/au-petit-bar-paris-75001-4/'

    if url != '' && url != nil
      domain = URI.parse(url).host.sub(/^www\./, '')
    else
      domain = ''
    end

    case domain
      when "716lavie.com"
        puts 'from 716lavie.com'

        page = Nokogiri.HTML(open(url))

        restaurant_name = page.css('div.foodnom').text.strip
        restaurant_name_in_array = page.css('div.foodnom').text.strip.split(" ")
        restaurant_adress = page.css('div.foodadress').text.strip
        restaurant_ids = Array.new


      when "mademoisellebonplan.fr"
        puts 'from mademoisellebonplan.fr'

        page = Nokogiri.HTML(open(url))

        restaurant_name = page.css('div.entry-content h6')[0].text.strip
        restaurant_name_in_array = page.css('div.entry-content h6')[0].text.strip.split(" ")
        restaurant_adress = page.css('div.entry-content h6')[1].text.strip
        restaurant_ids = Array.new

      when "glutencorner.com"
        puts 'from glutencorner.com'

        page = Nokogiri.HTML(open(url))

        restaurant_name = page.css('div.content h1.recette-titre').text.strip
        restaurant_name_in_array = page.css('div.content h1.recette-titre').text.strip.split(" ")
        restaurant_adress = page.css('p.recette-niveau')[2].text.strip
        restaurant_ids = Array.new

      else
        puts 'unknown to us'
        restaurant_adress = ''

    end

    if Geocoder.search(restaurant_adress).first != nil
      latitude = Geocoder.search(restaurant_adress).first.data["geometry"]["location"]["lat"]
      longitude = Geocoder.search(restaurant_adress).first.data["geometry"]["location"]["lng"]

      restaurants = Restaurant.where(["latitude < ? and latitude > ? and longitude < ? and longitude > ?", latitude + delta_latitude, latitude - delta_latitude, longitude + delta_longitude, longitude - delta_longitude])

      if restaurants != nil
        restaurants.each do |restaurant|
          restaurant_name_in_array.each do |word|
            if is_comparable_in_title(word) && (restaurant.name.include? word)
              restaurant_ids << restaurant.id
            else
              # no words in common in the title
            end
          end
        end
      else
        # no restaurants in specified zone in db
      end

      if restaurant_ids.length == 1
        restaurant = Restaurant.find(restaurant_ids).first
      else 
        # multiple restaurants found in zone and that matches the title
      end

    else
      # no restaurants in specified zone from referer crawling and geocoder
    end

    if restaurant != nil && params['influencer_id'] != nil && params['influencer_id'].to_i != 0 && User.where(id: params['influencer_id'].to_i).length == 1
      if Rails.env.production? == true
        @tracker.track('Wishlist From Influencer', { "influencer" => User.find(params['influencer_id'].to_i).name })
      end

      if current_user != nil # is already looged in, add wish immediately
        influencer = User.find(params['influencer_id'].to_i)

        if Wish.where(user_id: current_user.id, restaurant_id: restaurant.id).length > 0
          # already wishlisted
          redirect_to wish_failed_subscribers_path(message: 'already_wishlisted')
        elsif Recommendation.where(user_id: current_user.id, restaurant_id: restaurant.id).length > 0
          # already recommended
          redirect_to wish_failed_subscribers_path(message: 'already_recommended')
        else
          Wish.create(user_id: current_user.id, restaurant_id: restaurant.id, influencer_id: influencer.id)
          @tracker.track(current_user.id, 'New Wish', { "restaurant" => restaurant.name, "user" => current_user.name, "source" => "influencer", "influencer" => influencer.name })
          redirect_to wish_success_subscribers_path
        end
      else # show login page to add wish
        @user = User.new

        if (restaurant != nil)
          @restaurant = restaurant
          @influencer_id = User.find(params['influencer_id'].to_i).id
          @picture = @restaurant.restaurant_pictures.first ? @restaurant.restaurant_pictures.first.picture : @restaurant.picture_url
        else
          redirect_to wish_failed_subscribers_path(message: 'restaurant_inexistant')
        end
      end

    else
      redirect_to root_path
    end
  end

  def wish_success
    if current_user == nil
      redirect_to root_path
    end
  end

  def wish_failed
    if current_user == nil
      redirect_to root_path
    end

    if params['message'] == 'already_wishlisted'
      @message = 'Tu as déja ce restaurant sur ta wishlist'
    elsif params['message'] == 'already_recommended'
      @message = 'Tu as déja recommandé ce restaurant'
    elsif params['message'] == 'restaurant_inexistant'
      @message = 'Le restaurant que tu essaies de mettre sur ta wishlist n\'existe pas :\'('
    end
  end

  private

  def is_comparable_in_title(word)
    excluded_words = ['les', 'des', 'bar', 'restaurant']
    return word.length > 2 && !(excluded_words.include? word.downcase)
  end

end
