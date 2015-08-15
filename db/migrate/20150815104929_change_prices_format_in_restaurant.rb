class ChangePricesFormatInRestaurant < ActiveRecord::Migration
  def change
    change_column :restaurants, :price_starter1, :float
    change_column :restaurants, :price_starter2, :float
    change_column :restaurants, :price_main_course1, :float
    change_column :restaurants, :price_main_course2, :float
    change_column :restaurants, :price_main_course3, :float
    change_column :restaurants, :price_dessert1, :float
    change_column :restaurants, :price_dessert2, :float
  end
end
