class Restaurant < ActiveRecord::Base
  has_many :restaurant_pictures
  has_many :recommendations
  belongs_to :food

  def number
    self.recommendations.count
  end

  def ambiences

    hash = Hash.new(0)

    self.recommendations.each do |reco|
      reco.ambiences.each do |ambience|
        hash[ambience] += 1
      end
    end
    hash.sort_by { |_name, count| -count }.first(2).to_h
  end

  def strengths

    hash = Hash.new(0)

    self.recommendations.each do |reco|
      reco.strengths.each do |strength|
        hash[strength] += 1
      end
    end
    sorted = hash.sort_by { |_name, count| -count }.first(3).to_h
    # rajouter les photos pour chacun des 3

    end
  end

  def price
    array = []
    self.recommendations.each do |reco|
      array << reco.price
    end
    return array.inject(:+)/array.length
  end

end
