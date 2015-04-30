ActiveAdmin.register Restaurant do

  permit_params :name, :address, :food_id, :longitude, :latitude

end
