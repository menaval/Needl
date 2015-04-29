class Restaurant < ActiveRecord::Base

  has_many :restaurant_pictures, dependent: :destroy
  has_many :recommendations, dependent: :destroy
  belongs_to :food
  geocoded_by :address
  after_validation :geocode, if: :address_changed?
  def number
    self.recommendations.count
  end

  def ambiences

    hash = {}

    self.recommendations.each do |reco|
      reco.ambiences.each do |ambience|
        hash[ambience] ||= []
        hash[ambience] << reco.user_id
      end
    end
    hash.sort_by { |_name, ids| -ids.length }.first(2).to_h
  end

  def strengths

    hash = {}

    self.recommendations.each do |reco|
      reco.strengths.each do |strength|
        hash[strength] ||= []
        hash[strength] << reco.user_id
      end
    end

    hash.sort_by { |_name, ids| -ids.length }.first(3).to_h

    end

  def price
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
