ActiveAdmin.register Restaurant do

  permit_params :name, :address, :food_id, :longitude, :latitude, :phone_number, :picture_url, :price_range, :city, :postal_code, :full_address


end
