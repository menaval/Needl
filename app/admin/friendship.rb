ActiveAdmin.register Friendship do

  permit_params :sender_id, :receiver_id, :accepted, :sender_invisible, :receiver_invisible

  filter :sender, collection: User.all.order(:name)
  filter :receiver, collection: User.all.order(:name)

end
