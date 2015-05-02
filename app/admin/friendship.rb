ActiveAdmin.register Friendship do

  permit_params :sender_id, :receiver_id, :accepted, :interested


end
