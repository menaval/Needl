class RestaurantType < ActiveRecord::Base
  belongs_to :restaurant
  belongs_to :type
  validates :restaurant_id, :type_id, presence: true
  validates :restaurant_id, uniqueness: {scope: :type_id}
end
