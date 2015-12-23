class Restaurant < ActiveRecord::Base

  has_many :restaurant_pictures, dependent: :destroy
  has_many :recommendations, dependent: :destroy
  has_many :wishes, dependent: :destroy
  has_many :restaurant_subways, dependent: :destroy
  has_many :subways, :through => :restaurant_subways
  has_many :restaurant_types, dependent: :destroy
  has_many :types, :through => :restaurant_types

  belongs_to :food
  geocoded_by :full_address
  after_validation :geocode, if: :address_changed?

  scope :by_price_range, ->(price_selected) { where(price_range: price_selected.to_i) if price_selected.present?}
  scope :by_food,      ->(food)      { where("food_id = ?", food.to_i) if food.present? }
  scope :by_friend,    ->(friend)    {includes(:recommendations).where(recommendations: { user_id: friend.to_i }) if friend.present?}
  scope :by_subway,    ->(subway)    {includes(:restaurant_subways).where(restaurant_subways: { subway_id: subway.to_i}) if subway.present?}
  scope :by_ambience,  ->(ambience, user_id)  {includes(:recommendations).where("'#{ambience}' = ANY(recommendations.ambiences)").where(recommendations: {user_id: [User.find(user_id).my_visible_friends_ids_and_me]}).references(:recommendations)if ambience.present?}
  scope :by_occasion,  ->(occasion, user_id)  {includes(:recommendations).where("'#{occasion}' = ANY(recommendations.occasions)").where(recommendations: {user_id: [User.find(user_id).my_visible_friends_ids_and_me]}).references(:recommendations)if occasion.present?}

  def number_from_my_friends(current_user)
    number = 0
    self.recommendations.where(user_id: current_user.my_visible_friends_ids_and_me).each do |reco|
      number += 1
    end
    number
  end

  # def self.find_by_ambience(ambience, user_id)
  #   includes(:recommendations).where("'#{ambience}' = ANY(recommendations.ambiences)").where(recommendations: {user_id: [User.find(user_id).my_visible_friends_ids_and_me]}).references(:recommendations)if ambience.present?
  # end

# inutilisé car pour le site mais à mettre pour la migration !!!
  def ambiences_from_my_friends(current_user)
    array = []
    ambiences_list = ["chic", "festif", "convivial", "romantique", "branche", "typique", "cosy", "inclassable"]
    self.recommendations.where(user_id: current_user.my_visible_friends_ids_and_me + [553]).each do |reco|
      reco.ambiences.each do |number|
        ambience = ambiences_list[number.to_i - 1]
        array << ambience
      end
    end
    array.flatten.group_by(&:itself).sort_by { |_name, votes| -votes.length }.first(2).to_h.keys.first(2)
  end

# Inutilisé car pour le site
  def strengths_from_my_friends(current_user)
    array = []
    strengths_list = ["cuisine", "service", "cadre", "original", "copieux", "vins", "qte_prix"]
    self.recommendations.where(user_id: current_user.my_visible_friends_ids_and_me + [553]).each do |reco|
      reco.strengths.each do |number|
        strength = strengths_list[number.to_i - 1]
        array << strength
      end
    end
    array.flatten.group_by(&:itself).sort_by { |_name, votes| -votes.length }.first(2).to_h.keys.first(3)
  end

# Inutilisé car pour le site
  def occasions_from_my_friends(current_user)
    array = []
    occasions_list = ["business", "couple", "famille", "amis", "groupe", "brunch", "terrasse", "fast", "date"]

    self.recommendations.where(user_id: current_user.my_visible_friends_ids_and_me + [553]).each do |reco|
      reco.occasions.each do |number|
        occasion = occasions_list[number.to_i - 1]
        array << occasion
      end
    end
    array.flatten.group_by(&:itself).sort_by { |_name, votes| -votes.length }.first(2).to_h.keys.first(3)
  end


  def ambiences_from_my_friends_api(current_user)
    array = []
    self.recommendations.where(user_id: current_user.my_visible_friends_ids_and_me + [553]).each do |reco|
      array += reco.ambiences
    end
    array.flatten.group_by(&:itself).sort_by { |_id, votes| -votes.length }.first(2).to_h.keys.first(2)
  end

  def strengths_from_my_friends_api(current_user)
    array = []
    self.recommendations.where(user_id: current_user.my_visible_friends_ids_and_me + [553]).each do |reco|
      array += reco.strengths
    end
    array.flatten.group_by(&:itself).sort_by { |_id, votes| -votes.length }.first(2).to_h.keys.first(3)
  end

  def occasions_from_my_friends_api(current_user)
    array = []
    self.recommendations.where(user_id: current_user.my_visible_friends_ids_and_me + [553]).each do |reco|
      array += reco.occasions
    end
    array.flatten.group_by(&:itself).sort_by { |_id, votes| -votes.length }.first(2).to_h.keys.first(3)
  end

  def reviews_from_my_friends(current_user)
    hash = {}
    self.recommendations.where(user_id: current_user.my_visible_friends_ids_and_me + [553]).each do |reco|
      hash[reco.user_id] = [reco.review, reco.created_at]
    end
    hash.sort_by { |_user_id, content_and_date| content_and_date[1] }.reverse.to_h
  end

  def friends_wishing_this_restaurant(current_user)
    array = []
    self.wishes.where(user_id: current_user.my_visible_friends_ids_and_me).each do |wish|
      array += [wish.user_id]
    end
    array
  end

  def update_price_range(recommendation_price_range)
    self.price_range = recommendation_price_range.to_i
    self.save!
  end

  def closest_subway_id
    hash = {}
    self.subways.each do |subway|
      distance = self.bearing_to([subway.latitude, subway.longitude])
      hash[subway.id] = distance
    end
    hash.sort_by {|_key, value| value}.first[0]
  end

  def attribute_category_from_food

    variables_for_type_transfer
    food = self.food.name

    # attention, si on change l'ordre des types ou l'ordre des catégories dans le tableau ci dessus, tout devient faux
    @categories.each_with_index do |category, index|
      if category.include?(food)
        RestaurantType.create(restaurant_id: self.id, type_id: index + 1 )
      end
    end

  end

  def variables_for_type_transfer

    coreen = ["Korean"]
    thai = ["Thai"]
    chinois = ["Chinese", "Anhui", "Beijing", "Cantonese", "Aristocrat", "Chinese Breakfast", "Dim Sum", "Dongbei", "Fujian", "Guizhou", "Hainan", "Hakka", "Henan", "Hong Kong", "Huaiyang", "Hubei", "Hunan", "Imperial", "Jiangsu", "Jiangxi", "Macanese", "Manchu", "Peking Duck", "Shaanxi", "Shandong", "Shanghai", "Shanxi", "Szechuan", "Taiwanese", "Tianjin", "Xinjiang", "Yunnan", "Zhejiang"]
    indien = ["Indian", "Andhra", "Awadhi", "Bengali", "Chaat", "Chettinad", "Dhaba", "Dosa", "Goan", "Gujarati", "Hyderabadi", "Indian Chinese", "Indian Sweets", "Irani", "Jain", "Karnataka", "Kerala", "Maharashtrian", "Mughlai", "Multicuisine Indian", "North Indian", "Northeast Indian", "Parsi", "Punjabi", "Rajasthani", "South Indian", "Udupi"]
    japonais = ["Japanese", "Donburi", "Japanese Curry", "Kaiseki", "Kushikatsu", "Monjayaki", "Nabe", "Okonomiyaki", "Ramen", "Shabu-Shabu", "Soba", "Sukiyaki", "Takoyaki", "Tempura", "Tonkatsu", "Udon", "Unagi", "Wagashi", "Yakitori", "Yoshoku"]
    sushi = ["Sushi"]
    autres_asie = ["Asian", "Cambodian","Malaysian", "Mongolian", "Noodles", "Tibetan", "Vietnamese", "Dumplings", "Indonesian", "Acehnese", "Balinese", "Betawinese", "Indonesian Meatball Place", "Javanese", "Manadonese", "Padangnese", "Sundanese", "Pakistani", "Sri Lankan", "Filipino", "Himalayan", "Hotpot"]
    francais = ["Bistro", "Fondue", "French", "Gastropub"]
    italien = ["Italian", "Abruzzo", "Agriturismo", "Aosta", "Basilicata", "Calabria", "Campanian", "Emilia", "Friuli", "Ligurian", "Lombard", "Malga", "Marche", "Molise", "Piadineria", "Piedmontese", "Puglia", "Rifugio di Montagna", "Romagna", "Roman", "Sardinian", "Sicilian", "South Tyrolean", "Trattoria/Osteria", "Trentino", "Tuscan", "Umbrian", "Veneto"]
    pizza = ["Pizza"]
    burger = ["Burgers"]
    street_food = ["Bagels", "Falafel", "Fast Food", "Fish & Chips", "Food Court", "Food Truck", "Fried Chicken", "Friterie", "Hot Dogs", "Sandwiches", "Snacks", "Doner", "Kebab", "Kofte", "Wings"]
    autres_europe = ["Austrian", "Belgian", "Czech", "Eastern European", "Belarusian", "Romanian", "Tatar", "English", "German", "Greek", "Bougatsa Shops", "Cretan Restaurants", "Fish Tavernas", "Grilled Meat Restaurants", "Kafenia", "Magirio", "Meze Restaurants", "Modern Greek Restaurants", "Ouzeries", "Patsa Restaurants", "Souvlaki", "Tavernas", "Tsipouro Restaurants", "Hungarian", "Mediterranean", "Modern European", "Polish", "Portuguese", "Russian", "Blini", "Pelmeni", "Scandinavian", "Spanish", "Paella", "Swiss", "Ukrainian", "Varenyky", "West-Ukrainian"]
    viandes_et_grillades = ["American", "New American", "Australian", "BBQ", "Steakhouse"]
    oriental = ["Afghan", "Caucasian", "Moroccan", "Middle Eastern", "Persian", "Pakistani", "Turkish", "Borek", "Cigkofte", "Gozleme", "Kokore", "Manti", "Meyhane", "Pide", "Turkish Home Cooking"]
    mexicain = ["Mexican", "Burritos", "Tacos"]
    autres_latino = ["South American", "Argentinian", "Peruvian", "Brazilian", "Acai", "Baiano", "Central Brazilian", "Churrascaria", "Empadas", "Goiano", "Mineiro", "Northeastern Brazilian", "Northern Brazilian", "Pastelaria", "Southeastern Brazilian", "Southern Brazilian", "Tapiocaria", "Latin American", "Arepas", "Cuban", "Empanada"]
    fruits_de_mer = ["Seafood"]
    africain = ["African", "Ethiopian"]
    creole = ["Cajun / Creole", "Caribbean"]
    crepes = ["Creperie"]
    tapas = ["Tapas"]
    vegetarien = ["Vegetarian / Vegan"]

    @categories = [coreen, thai, chinois, indien, japonais, sushi, autres_asie, francais, italien, pizza, burger, street_food, autres_europe, viandes_et_grillades, oriental, mexicain, autres_latino, fruits_de_mer, africain, creole, crepes, tapas, vegetarien]

  end

end
