class Restaurant < ActiveRecord::Base

  has_many :restaurant_pictures, dependent: :destroy
  has_many :recommendations, dependent: :destroy
  belongs_to :food
  geocoded_by :address
  after_validation :geocode, if: :address_changed?

  scope :cheaper_than, ->(max_price) { where("restaurants.price <= ?", max_price.to_i) if max_price.present? }
  scope :by_food,      ->(food)      { where("food_id = ?", food.to_i) if food.present? }
  scope :by_friend,    ->(friend)    {includes(:recommendations).where(recommendations: { user_id: friend.to_i }) if friend.present?}

  def number_from_my_friends(current_user)
    number = 0
    self.recommendations.each do |reco|
      if current_user.my_friends.include?(User.find(reco.user_id)) || current_user == User.find(reco.user_id)
        number += 1
      end
    end
    number
  end

  def ambiences_from_my_friends(current_user)
    hash = {}
    self.recommendations.each do |reco|
      if current_user.my_friends.include?(User.find(reco.user_id)) || current_user == User.find(reco.user_id)
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
      if current_user.my_friends.include?(User.find(reco.user_id)) || current_user == User.find(reco.user_id)
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
      if current_user.my_friends.include?(User.find(reco.user_id)) || current_user == User.find(reco.user_id)
        if reco.review != ""
          hash[reco.user_id] = [reco.review, reco.created_at]
        end
      end
    end
    hash.sort_by { |_user_id, content_and_date| content_and_date[1] }.reverse.to_h
  end


  def recompute_price(recommendation_price)
    total = self.price * ( self.recommendation_ids.count - 1 )
    total += recommendation_price
    self.price = total / self.recommendation_ids.count
    self.save!
  end

  def recompute_with_previous_price(new_price, previous_price)
    total = self.price * self.recommendation_ids.count
    total = total - previous_price + new_price
    self.price = total / self.recommendation_ids.count
    self.save!
  end
end
