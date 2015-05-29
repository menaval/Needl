class Restaurant < ActiveRecord::Base

  has_many :restaurant_pictures, dependent: :destroy
  has_many :recommendations, dependent: :destroy
  has_many :restaurant_subways, dependent: :destroy
  has_many :subways, :through => :restaurant_subways

  belongs_to :food
  geocoded_by :address
  after_validation :geocode, if: :address_changed?

  scope :cheaper_than, ->(max_price) { where("restaurants.price <= ?", max_price.to_i) if max_price.present? }
  scope :by_food,      ->(food)      { where("food_id = ?", food.to_i) if food.present? }
  scope :by_friend,    ->(friend)    {includes(:recommendations).where(recommendations: { user_id: friend.to_i }) if friend.present?}
  scope :by_subway,    ->(subway)    {includes(:restaurant_subways).where(restaurant_subways: { subway_id: subway.to_i}) if subway.present?}

  def number_from_my_friends(current_user)
    number = 0
    self.recommendations.each do |reco|
      if User.where(id: current_user.my_friends_ids).include?(User.find(reco.user_id)) || current_user == User.find(reco.user_id)
        number += 1
      end
    end
    number
  end

  def ambiences_from_my_friends(current_user)
    hash = {}
    self.recommendations.each do |reco|
      if User.where(id: current_user.my_friends_ids).include?(User.find(reco.user_id)) || current_user == User.find(reco.user_id)
        reco.ambiences.each do |number|
          ambiences_list = ["chic", "festif", "typique", "ensoleille", "fast_and_good"]
          ambience = ambiences_list[number.to_i - 1]
          hash[ambience] ||= []
          hash[ambience] << reco.user_id
        end
      end
    end
    hash.sort_by { |_name, ids| -ids.length }.first(2).to_h
  end

  def strengths_from_my_friends(current_user)
    hash = {}
    self.recommendations.each do |reco|
      if User.where(id: current_user.my_friends_ids).include?(User.find(reco.user_id)) || current_user == User.find(reco.user_id)
        reco.strengths.each do |number|
          ambiences_list = ["cuisine", "service", "cadre", "original", "copieux", "vins", "qualite_prix"]
          ambience = ambiences_list[number.to_i - 1]
          hash[ambience] ||= []
          hash[ambience] << reco.user_id
        end
      end
    end
    hash.sort_by { |_name, ids| -ids.length }.first(3).to_h
  end

  def reviews_from_my_friends(current_user)
    hash = {}
    self.recommendations.each do |reco|
      if User.where(id: current_user.my_friends_ids).include?(User.find(reco.user_id)) || current_user == User.find(reco.user_id)
        if reco.review != ""
          hash[reco.user_id] = [reco.review, reco.created_at]
        end
      end
    end
    hash.sort_by { |_user_id, content_and_date| content_and_date[1] }.reverse.to_h
  end

  def create_price(recommendation_price)
    self.price = recommendation_price
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

end
