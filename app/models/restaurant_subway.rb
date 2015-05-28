class RestaurantSubway < ActiveRecord::Base

  belongs_to :restaurant
  belongs_to :subway
  validates :restaurant_id, :subway_id, presence: true
  validates :restaurant_id, uniqueness: {scope: :subway_id}

end