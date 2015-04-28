class Restaurant < ActiveRecord::Base
  has_many :restaurant_pictures
  has_many :recommendations

end
