class TasteCorrespondence < ActiveRecord::Base

  belongs_to :member_one, :class_name => "User"
  belongs_to :member_two, :class_name => "User"
  validates :member_one_id, :member_two_id, presence: true
  validates :member_one_id, uniqueness: {scope: :member_two_id}

end
