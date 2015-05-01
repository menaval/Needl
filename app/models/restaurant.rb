class Restaurant < ActiveRecord::Base

  has_many :restaurant_pictures, dependent: :destroy
  has_many :recommendations, dependent: :destroy, after_add: :recompute_price
  belongs_to :food
  geocoded_by :address
  after_validation :geocode, if: :address_changed?

  scope :cheaper_than, ->(max_price) { where { |restaurant| restaurant.price < max_price.to_i } if max_price }
  scope :by_ambience,  ->(ambience)  { where { |restaurant| restaurant.ambiences == ambience } if ambience }
  scope :by_strength,  ->(strength)  { where { |restaurant| restaurant.strengths == strength } if strength }
  # scope :by_food,      ->(food)      { where { |restaurant| restaurant.food_id == food.to_i } if food }

  def number
    self.recommendations.count
  end

  def ambiences
    hash = {}
    self.recommendations.each do |reco|
      reco.ambiences.each do |number|
        ambience = ""
        case number.to_i
          when 1
            ambience = "chic"
          when 2
            ambience = "festif"
          when 3
            ambience = "typique"
          when 4
            ambience = "en-cas-de-soleil"
          when 5
            ambience = "fast-and-good"
        end
        hash[ambience] ||= []
        hash[ambience] << reco.user_id
      end
    end
    hash.sort_by { |_name, ids| -ids.length }.first(2).to_h
  end

  def strengths
    hash = {}
    self.recommendations.each do |reco|
      reco.strengths.each do |number|
        strength = ""
        case number.to_i
          when 1
            strength = "nourriture"
          when 2
            strength = "service"
          when 3
            strength = "cadre"
          when 4
            strength = "originalite"
          when 5
            strength = "generosite"
          when 6
            strength = "carte-des-vins"
          when 7
            strength = "rapport-qualite-prix"
        end
        hash[strength] ||= []
        hash[strength] << reco.user_id
      end
    end
    hash.sort_by { |_name, ids| -ids.length }.first(3).to_h
  end

  def recompute_price(recommendation)
    self.price += recommendation.price
    self.price /= self.recommendation_ids.count
    self.save!
  end

  def old_price
    array = []
    self.recommendations.each do |reco|
      array << reco.price
    end
    if array == []
      return 0
    else
      return array.inject(:+)/array.length
    end
  end
end
