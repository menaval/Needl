class Followership < ActiveRecord::Base
  belongs_to :follower, :class_name => "User"
  belongs_to :following, :class_name => "User"
  validates :follower_id, :following_id, presence: true
  validates :follower_id, uniqueness: {scope: :following_id}

end
