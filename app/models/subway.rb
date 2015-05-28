class Subway < ActiveRecord::Base
  has_many :restaurant_subways, dependent: :destroy
  has_many :restaurants, :through => :restaurant_subways

end