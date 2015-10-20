class Expert < ActiveRecord::Base

  has_many :recommendations, dependent: :destroy
  has_many :followerships, dependent: :destroy
  has_attached_file :picture,
    styles: { large: "800x800", medium: "300x300>", thumb: "50x50#" }
  validates_attachment_content_type :picture,
    content_type: /\Aimage\/.*\z/

end
