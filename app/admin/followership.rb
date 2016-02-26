ActiveAdmin.register Followership do

  permit_params :follower_id, :following_id

  filter :follower, collection: User.all.order(:name)
  filter :following, collection: User.where(public: true).order(:name)


end