class AddCityAndPostalCodeToRestaurants < ActiveRecord::Migration
  def change
    add_column :restaurants, :city, :string
    add_column :restaurants, :postal_code, :string
    add_column :restaurants, :full_address, :string
  end
end
