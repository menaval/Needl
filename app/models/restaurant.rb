class Restaurant < ActiveRecord::Base

  has_many :restaurant_pictures, dependent: :destroy
  has_many :recommendations, dependent: :destroy, after_add: :recompute_price
  belongs_to :food
  geocoded_by :address
  after_validation :geocode, if: :address_changed?

  scope :cheaper_than, ->(max_price) { where("price < ?", max_price.to_i) if max_price.present? }
  #scope :by_ambience,  ->(ambiences) {
  #  if ambiences.present?
  #    where("ARRAY(ambiences) && ARRAY(?)", ambiences)
  #  end
  #}
  # scope :by_strength,  ->(strengths)  { where("strengths = ?", strengths) if strengths.present? }
  scope :by_food,      ->(food)      { where("food_id = ?", food.to_i) if food.present? }

  def number
    self.recommendations.count
  end

  def recompute_ambiences
    self.ambiences = self.recommendations
    .map(&:ambiences)
    .flatten
    .each_with_object(Hash.new(0)) { |num,counts| counts[num] += 1 }
    .sort_by { |_ambience, count| -count }
    .take(2)
    .to_h.keys

    self.save!
  end

  def recompute_strengths
    self.strengths = self.recommendations
    .map(&:strengths)
    .flatten
    .each_with_object(Hash.new(0)) { |num,counts| counts[num] += 1 }
    .sort_by { |_ambience, count| -count }
    .take(2)
    .to_h.keys

    self.save!
  end

  def get_ambiences_with_users
    hash = {}
    self.recommendations.each do |reco|
      reco.ambiences.each do |number|
        ambiences_list = ["chic", "festif", "typique", "en_cas_de_soleil", "fast_and_good"]
        ambience = ambiences_list[number.to_i - 1]
        hash[ambience] ||= []
        hash[ambience] << reco.user_id
      end
    end
    hash.sort_by { |_name, ids| -ids.length }.first(2).to_h
  end

  def get_strengths_with_users
    hash = {}
    self.recommendations.each do |reco|
      reco.strengths.each do |number|
        strengths_list = ["nourriture", "service", "cadre", "originalite", "generosite", "carte_des_vins", "rapport_qualite_prix"]
        strength = strengths_list[number.to_i - 1]
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
