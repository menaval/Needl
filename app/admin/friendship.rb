ActiveAdmin.register Friendship do

  permit_params :sender_id, :receiver_id, :accepted, :sender_invisible, :receiver_invisible


end
