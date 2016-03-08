class NotInterestedRelation < ActiveRecord::Base

  belongs_to :refuser, :class_name => "User"
  belongs_to :refused, :class_name => "User"
  validates :refuser_id, :refused_id, presence: true
  validates :refuser_id, uniqueness: {scope: :refused_id}

end