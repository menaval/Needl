class Friendship < ActiveRecord::Base
  belongs_to :sender, :class_name => "User"
  belongs_to :receiver, :class_name => "User"
  # vérifier la dénomination sender vs sender_id (idem pour receiver)
  validates :sender_id, :receiver_id, presence: true
  validates :sender_id, uniqueness: {scope: :receiver_id}

  def no_reciprocity
    if Friendship.where(receiver: self.sender, sender: self.receiver).any?
      errors.add :sender, "Friendship already exists"
    end
  end
end
