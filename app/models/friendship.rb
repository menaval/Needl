class Friendship < ActiveRecord::Base
  belongs_to :sender, :class_name => "User"
  belongs_to :receiver, :class_name => "User"
  validates :sender_id, :receiver_id, presence: true
  validates :sender_id, uniqueness: {scope: :receiver_id}

end
