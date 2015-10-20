class Followership < ActiveRecord::Base
  belongs_to :user
  belongs_to :expert
  validates :user_id, :expert_id, presence: true
  validates :expert_id, uniqueness: {scope: :user_id}
end
