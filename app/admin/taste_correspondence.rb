ActiveAdmin.register TasteCorrespondence do

  permit_params :member_one_id, :member_two_id, :number_of_shared_restaurants, :category

  filter :member_one, collection: User.all.order(:name)
  filter :member_two, collection: User.all.order(:name)
  filter :number_of_shared_restaurants
  filter :category

end