ActiveAdmin.register Restaurant do

  permit_params :name, :address, :food_id, :longitude, :latitude, :phone_number, :picture_url, :price_range, :city, :postal_code, :full_address, :starter1, :starter2, :price_starter1, :price_starter2, :main_course1, :main_course2, :main_course3, :price_main_course1, :price_main_course2, :price_main_course3, :dessert1, :dessert2, :price_dessert1, :price_dessert2


end
