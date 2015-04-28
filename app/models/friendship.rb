class Friendship < ActiveRecord::Base
  belongs_to :sender, :class_name => "User"
  belongs_to :receiver, :class_name => "User"
  # vérifier la dénomination sender vs sender_id (idem pour receiver)
end
