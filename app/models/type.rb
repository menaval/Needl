class Type < ActiveRecord::Base
  has_many :restaurant_types, dependent: :destroy
  has_many :restaurants, :through => :restaurant_types

  has_attached_file :picture,
      styles: { medium: "300x300>", thumb: "100x100>" }
    validates_attachment_content_type :picture,
      content_type: /\Aimage\/.*\z/

end
