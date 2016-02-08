ActiveAdmin.register RestaurantType do

  permit_params :restaurant_id, :type_id

  form do |f|
    f.inputs "Restaurant Type" do
      f.input :restaurant, collection: Restaurant.all.order(:name)
      f.input :type, collection: Type.all.order(:name)
    end
    f.actions
  end

end