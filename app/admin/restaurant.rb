ActiveAdmin.register Restaurant do

  permit_params :name, :address, :food_id, :longitude, :latitude, :price, :phone_number, :picture_url, :price_range


end
