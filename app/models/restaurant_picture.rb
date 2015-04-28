class RestaurantPicture < ActiveRecord::Base
  belongs_to :restaurant

  has_attached_file :picture,
      styles: { medium: "300x300>", thumb: "100x100>" }
  validates_attachment_content_type :picture,
    content_type: /\Aimage\/.*\z/
end
