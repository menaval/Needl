ActiveAdmin.register RestaurantPicture do
  permit_params :picture, :restaurant_id, :user_id

  filter :restaurant, collection: Restaurant.all.order(:name)

  form do |f|
    f.inputs "Picture" do
      f.input :restaurant, collection: Restaurant.all.order(:name)
      f.input :user, collection: User.where(public: true).order(:name)
      f.file_field :picture
    end
    f.actions
  end

end
