class Restaurant < ActiveRecord::Base

  has_many :restaurant_pictures, dependent: :destroy
  has_many :recommendations, dependent: :destroy
  has_many :wishes, dependent: :destroy
  has_many :restaurant_subways, dependent: :destroy
  has_many :subways, :through => :restaurant_subways

  belongs_to :food
  geocoded_by :full_address
  after_validation :geocode, if: :address_changed?

  scope :by_price_range, ->(price_selected) { where(price_range: price_selected.to_i) if price_selected.present?}
  scope :by_food,      ->(food)      { where("food_id = ?", food.to_i) if food.present? }
  scope :by_friend,    ->(friend)    {includes(:recommendations).where(recommendations: { user_id: friend.to_i }) if friend.present?}
  scope :by_subway,    ->(subway)    {includes(:restaurant_subways).where(restaurant_subways: { subway_id: subway.to_i}) if subway.present?}
  scope :by_ambience,  ->(ambience, user_id)  {includes(:recommendations).where("'#{ambience}' = ANY(recommendations.ambiences)").where(recommendations: {user_id: [User.find(user_id).my_visible_friends_ids_and_me]}).references(:recommendations)if ambience.present?}

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

  def ambiences_from_my_friends(current_user)
    array = []
    ambiences_list = ["chic", "festif", "typique", "ensoleille", "fast", "casual"]
    self.recommendations.where(user_id: current_user.my_visible_friends_ids_and_me).each do |reco|
      reco.ambiences.each do |number|
        ambience = ambiences_list[number.to_i - 1]
        array << ambience
      end
    end
    array.flatten.group_by(&:itself).sort_by { |_name, votes| -votes.length }.first(2).to_h.keys.first(2)
  end

  def strengths_from_my_friends(current_user)
    array = []
    strengths_list = ["cuisine", "service", "cadre", "original", "copieux", "vins", "qte_prix"]
    self.recommendations.where(user_id: current_user.my_visible_friends_ids_and_me).each do |reco|
      reco.strengths.each do |number|
        strength = strengths_list[number.to_i - 1]
        array << strength
      end
    end
    array.flatten.group_by(&:itself).sort_by { |_name, votes| -votes.length }.first(2).to_h.keys.first(3)
  end

  def ambiences_from_my_friends_api(current_user)
    array = []
    self.recommendations.where(user_id: current_user.my_visible_friends_ids_and_me).each do |reco|
      array += reco.ambiences
    end
    array.flatten.group_by(&:itself).sort_by { |_id, votes| -votes.length }.first(2).to_h.keys.first(2)
  end

  def strengths_from_my_friends_api(current_user)
    array = []
    self.recommendations.where(user_id: current_user.my_visible_friends_ids_and_me).each do |reco|
      array += reco.strengths
    end
    array.flatten.group_by(&:itself).sort_by { |_id, votes| -votes.length }.first(2).to_h.keys.first(3)
  end

  def reviews_from_my_friends(current_user)
    hash = {}
    self.recommendations.where(user_id: current_user.my_visible_friends_ids_and_me).each do |reco|
      if reco.review == ""
        reco.review = "Je recommande !"
      end
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



   # Methode a garder si un jour je veux ajouter qui a recommandé avec quelle ambience
     # def ambiences_from_my_friends(current_user)
     #   hash = {}
     #   ambiences_list = ["chic", "festif", "typique", "ensoleille", "fast", "casual"]
     #   self.recommendations.where(user_id: current_user.my_visible_friends_ids_and_me).each do |reco|
     #     reco.ambiences.each do |number|
     #       ambience = ambiences_list[number.to_i - 1]
     #       hash[ambience] ||= []
     #       hash[ambience] << reco.user_id
     #     end
     #   end
     #   hash.sort_by { |_name, ids| -ids.length }.first(2).to_h
     # end

     # Idem avec les forces
       # def strengths_from_my_friends(current_user)
       #   hash = {}
       #   strengths_list = ["cuisine", "service", "cadre", "original", "copieux", "vins", "qte_prix"]
       #   self.recommendations.where(user_id: current_user.my_visible_friends_ids_and_me).each do |reco|
       #     reco.strengths.each do |number|
       #       ambience = strengths_list[number.to_i - 1]
       #       hash[ambience] ||= []
       #       hash[ambience] << reco.user_id
       #     end
       #   end
       #   hash.sort_by { |_name, ids| -ids.length }.first(3).to_h
       # end

end
