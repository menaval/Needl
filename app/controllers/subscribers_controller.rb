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

  def new
    if params['message'] == 'facebook_link'
      @facebook_link = true
    end
  end

  def login
    delta_latitude = 0.0004
    delta_longitude = 0.0008

    url = request.referer
    @client_ip = request.remote_ip

    if Rails.env.development? == true
      url = 'http://italieaparis.net/adresses/adr/pizzeria-mipi'
    end

    if url != '' && url != nil
      domain = URI.parse(url).host.sub(/^www\./, '')
    else
      domain = ''
    end

    case domain
      when "italieaparis.net"
        if Rails.env.development? == true
          puts 'from italieaparis.net'
        end

        if Rails.env.production? == true
          influencer = User.find(854)
          @tracker.track(@client_ip, 'Wishlist Page From Influencer', {"influencer" => influencer.name})
        end

        page = Nokogiri.HTML(open(url))

        restaurant_name = page.css('div.infos li')[0].text.strip
        restaurant_name_in_array = restaurant_name.split(" ")
        restaurant_address = page.css('div.infos li')[1].text.strip
        restaurant_ids = []

      when "716lavie.com"
        if Rails.env.development? == true
          puts 'from 716lavie.com'
        end

        if Rails.env.production? == true
          influencer = User.find(920)
          @tracker.track(@client_ip, 'Wishlist Page From Influencer', {"influencer" => influencer.name})
        end

        page = Nokogiri.HTML(open(url))

        restaurant_name = page.css('div.foodnom').text.strip
        restaurant_name_in_array =restaurant_name.split(" ")
        restaurant_address = page.css('div.foodadress').text.strip
        restaurant_ids = []

      when "mademoisellebonplan.fr"
        if Rails.env.development? == true
          puts 'from mademoisellebonplan.fr'
        end

        if Rails.env.production? == true
          influencer = User.find(759)
          @tracker.track(@client_ip, 'Wishlist Page From Influencer', {"influencer" => influencer.name})
        end

        page = Nokogiri.HTML(open(url))

        restaurant_name = page.css('div.entry-content h6')[0].text.strip
        restaurant_name_in_array = restaurant_name.split(" ")
        restaurant_address = page.css('div.entry-content h6')[1].text.strip
        restaurant_ids = []

      when "glutencorner.com"
        if Rails.env.development? == true
          puts 'from glutencorner.com'
        end

        if Rails.env.production? == true
          influencer = User.find(765)
          @tracker.track(@client_ip, 'Wishlist Page From Influencer', {"influencer" => influencer.name})
        end

        page = Nokogiri.HTML(open(url))

        special_character_index = []

        restaurant_name = page.css('div.content h1.recette-titre').text.strip
        special_character_index << restaurant_name.index('(') 
        special_character_index << restaurant_name.index('-') 
        special_character_index << restaurant_name.index('–') 
        special_character_index << restaurant_name.index(':')
        special_character_index_minimum = special_character_index.compact.min

        if special_character_index_minimum != nil
          restaurant_name = restaurant_name[0, special_character_index_minimum]
        end

        restaurant_name_in_array = restaurant_name.split(" ")
        restaurant_address = page.css('p.recette-niveau')[2].text.strip
        restaurant_ids = []

      when "because-gus.com"
        if Rails.env.development? == true
          puts 'from because-gus.com'
        end

        if Rails.env.production? == true
          influencer = User.find(852)
          @tracker.track(@client_ip, 'Wishlist Page From Influencer', {"influencer" => influencer.name})
        end

        page = Nokogiri.HTML(open(url))

        special_character_index = []

        restaurant_name = page.css('h1.blog-title a').text.strip
        special_character_index << restaurant_name.index('(') 
        special_character_index << restaurant_name.index('-') 
        special_character_index << restaurant_name.index('–') 
        special_character_index << restaurant_name.index(':')
        special_character_index_minimum = special_character_index.compact.min

        if special_character_index_minimum != nil
          restaurant_name = restaurant_name[0, special_character_index_minimum]
        end
        restaurant_name_in_array = restaurant_name.split(" ")

        paragraphs = page.css('div.blog-excerpt p')
        index = 0
        key = 0
        previous_is_numeric = false

        # Try and find two consecutive paragraphs starting with a number
        paragraphs.each do |paragraph|
          first_letter = paragraph.text.strip[0, 1]

          if numeric(first_letter)
            if previous_is_numeric
              key = index
            else
              previous_is_numeric = true
            end
          else
            previous_is_numeric = false
          end

          index += 1
        end

        # no matches found while looping in the paragraphs
        if key == 0 
          # there might be the address here
          if page.css('span.editor_black').length > 0
            potential_address = page.css('span.editor_black')[0].text.strip

            # Check if it's not a phone number
            if (potential_address[2,1] != '.' || potential_address[5,1] != '.' || potential_address[8,1] != '.' || potential_address[11,1] != '.') && numeric(potential_address[0,1])
              # Address found
              restaurant_address = potential_address
            else
              # Address not found
              if Rails.env.development? == true
                puts 'unknown to us'
              end

              if Rails.env.production? == true
                @tracker.track(@client_ip, 'Crawling failed', {'url' => url})
              end

              restaurant_address = ''
              @error_message = 'crawling_failed'
            end
          else
            # Address not found
            if Rails.env.development? == true
              puts 'unknown to us'
            end

            if Rails.env.production? == true
              @tracker.track(@client_ip, 'Crawling failed', {'url' => url})
            end

            restaurant_address = ''
            @error_message = 'crawling_failed'
          end
        else
          # Address found
          restaurant_address = paragraphs[key - 1].text.strip + " " + paragraphs[key].text.strip
        end

        restaurant_ids = []

      else
        # Refere not in our db
        if Rails.env.development? == true
          puts 'unknown to us'
        end
        restaurant_address = ''
        @error_message = 'unknown_referer'

    end

    if Rails.env.development? == true 
      influencer = User.find(1)
    end

    if Geocoder.search(restaurant_address).first != nil
      latitude = Geocoder.search(restaurant_address).first.data["geometry"]["location"]["lat"]
      longitude = Geocoder.search(restaurant_address).first.data["geometry"]["location"]["lng"]

      restaurants = Restaurant.where(["latitude < ? and latitude > ? and longitude < ? and longitude > ?", latitude + delta_latitude, latitude - delta_latitude, longitude + delta_longitude, longitude - delta_longitude])

      if restaurants != nil && restaurants.length > 0
        found_restaurant = false

        # search in title
        restaurants.each do |restaurant|
          restaurant_name_in_array.each do |word|
            if is_comparable_in_title(word) && (restaurant.name.include? word)
              restaurant_ids << restaurant.id
              found_restaurant = true
            end
          end
        end

        # no words in common in the title => search in foursquare
        if found_restaurant == false
          search_in_foursquare(restaurant_name, latitude, longitude, url)
        end
      else
        # no restaurants in specified zone in db, we search in Foursquare
        search_in_foursquare(restaurant_name, latitude, longitude, url)
      end

      if restaurant_ids.uniq.length == 1
        @origin = 'db'
        @restaurant = Restaurant.find(restaurant_ids).first
      else 
        if @restaurant == nil
          # multiple restaurants matching the location and name
          @error_message = 'multiple_restaurants'

          if Rails.env.production? == true
            @tracker.track(@client_ip, 'Multiple restaurants found', {'url' => url})
          end
        end
      end

    else
      # no restaurants in specified zone from referer crawling and geocoder
      @error_message = 'error_with_geocoder'
    end

    if @restaurant != nil
      if current_user != nil 
        # is already looged in, add wish immediately
        if Wish.where(user_id: current_user.id, restaurant_id: @restaurant.id).length > 0
          # already wishlisted
          redirect_to wish_failed_subscribers_path(message: 'already_wishlisted')
        elsif Recommendation.where(user_id: current_user.id, restaurant_id: @restaurant.id).length > 0
          # already recommended
          redirect_to wish_failed_subscribers_path(message: 'already_recommended')
        else
          if @origin == 'db' || @origin = 'foursquare'
            Wish.create(user_id: current_user.id, restaurant_id: @restaurant.id, influencer_id: influencer.id)
          end
          if Rails.env.production? == true
            @tracker.track(current_user.id, 'New Wish', { "restaurant" => @restaurant.name, "user" => current_user.name, "source" => "influencer", "influencer" => influencer.name })
          end
          redirect_to wish_success_subscribers_path
        end
      else # show login page to add wish
        @user = User.new

        if (@restaurant != nil)
          @influencer_id = influencer.id
          @picture = @restaurant.restaurant_pictures.first ? @restaurant.restaurant_pictures.first.picture : @restaurant.picture_url
        else
          redirect_to restaurant_failed_subscribers_path(message: 'inexistant_restaurant')
        end
      end

    else
      case @error_message
        when "multiple_restaurants"
          redirect_to restaurant_failed_subscribers_path(message: 'multiple_restaurants')
        
        when "inexistant_restaurant"
          redirect_to restaurant_failed_subscribers_path(message: 'inexistant_restaurant')

        else
          redirect_to root_path

      end
    end
  end

  def wish_success
    if current_user == nil
      redirect_to root_path
    end

    case params['message']
      when 'account_creation'
        @message_welcome = "<h1>Bienvenue sur Needl !</h1><h2>Needl c'est l'application pour trouver où diner en moins de 5 minutes !</h2>"
        @message = "<h3>Ton restaurant a bien été ajouté à ta wishlist ! Tu peux le retrouver sur l'application, disponible sur l'AppStore.</h3>"

      else 
        @message_welcome = nil
        @message = "<h2>Ton restaurant a bien été ajouté à ta wishlist ! Tu peux le retrouver sur l'application, disponible sur l'AppStore.</h2>"

    end
  end

  def wish_failed
    if current_user == nil
      redirect_to root_path
    end

    case params['message']
      when 'already_wishlisted'
        @message = 'Tu as déja ce restaurant sur ta wishlist'
    
      when 'already_recommended'
        @message = 'Tu as déja recommandé ce restaurant'

      else 
        @message = 'Une erreur s\'est produite lors de l\'ajout du restaurant à ta wishlist, ré-essaie un peu plus tard'

    end
  end

  def restaurant_failed
    case params['message']
      when 'inexistant_restaurant'
        @message = 'Le restaurant que tu essaies de mettre sur ta wishlist n\'existe pas dans notre base de données :\'( Nous allors y remédier au plus vite.'

      when 'multiple_restaurants'
        @message = 'Une erreur s\'est produite lors de l\'ajout du restaurant à ta wishlist, ré-essaie un peu plus tard'

      else 
        @message = 'Une erreur s\'est produite lors de l\'ajout du restaurant à ta wishlist, ré-essaie un peu plus tard'

    end
  end

  private

  def is_comparable_in_title(word)
    excluded_words = ['les', 'des', 'bar', 'restaurant']
    return word.length > 2 && !(excluded_words.include? word.downcase)
  end

  def search_in_foursquare(name, latitude, longitude, url)
    client = Foursquare2::Client.new(
        api_version:    ENV['FOURSQUARE_API_VERSION'],
        client_id:      ENV['FOURSQUARE_CLIENT_ID'],
        client_secret:  ENV['FOURSQUARE_CLIENT_SECRET'])

    # On cherche les restaurants à partir de leurs coordonnés et on prend ceux à moins de 70 mètres (il y a des décalages avec ce que geocoder fait, car apparemment il change la géoloc une fois le restaurant crée, donc on met un peu de marge) avec en query leur nom
    search = client.search_venues(
      categoryId: "#{ENV['FOURSQUARE_FOOD_CATEGORY']},#{ENV['FOURSQUARE_BAR_CATEGORY']}",
      intent:     'browse',
      ll:         "#{latitude},#{longitude}",
      radius:     '70',
      query:      name
    )

    # On récupère tous les restaurants récupérés
    array = []
    search.first[1].each do |restaurant_foursquare|
      array << restaurant_foursquare
    end

    # Si un seul restaurant de récupéré, on l'ajoute en bdd
    if array.length > 0
      first_restaurant = array.first
      @restaurant = Restaurant.where(name: first_restaurant.name).first_or_create(
        name:               first_restaurant.name,
        address:            "#{first_restaurant.location.address}",
        city:               "#{first_restaurant.location.city}",
        postal_code:        "#{first_restaurant.location.postalCode}",
        full_address:       "#{first_restaurant.location.address}, #{first_restaurant.location.city} #{first_restaurant.location.postalCode}",
        food:               Food.where(name: first_restaurant.categories[0].shortName).first_or_create,
        latitude:           first_restaurant.location.lat,
        longitude:          first_restaurant.location.lng,
        price_range:        first_restaurant.attributes ? (first_restaurant.attributes.groups[0] ? first_restaurant.attributes.groups[0].items[0].priceTier : nil) : nil,
        picture_url:        first_restaurant.photos ? (first_restaurant.photos.groups[0] ? "#{first_restaurant.photos.groups[0].items[0].prefix}1000x1000#{first_restaurant.photos.groups[0].items[0].suffix}" : "http://needl.s3.amazonaws.com/production/restaurant_pictures/pictures/000/restaurant%20default.jpg") : "http://needl.s3.amazonaws.com/production/restaurant_pictures/pictures/000/restaurant%20default.jpg",
        phone_number:       first_restaurant.contact.phone ? first_restaurant.contact.phone : "",
        foursquare_id:      first_restaurant.id,
        foursquare_rating:  first_restaurant.rating
      )
      @origin = 'foursquare'
    else
      # pas de restaurants correspondent à la recherche
      @error_message = 'inexistant_restaurant'

      if Rails.env.production? == true
        @tracker.track(@client_ip, 'No restaurants found', { 'url' => url })
      end
    end
  end

  def numeric(character)
    character =~ /[[:digit:]]/
  end

end
