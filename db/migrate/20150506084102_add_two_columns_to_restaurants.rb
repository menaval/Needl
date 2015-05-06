class AddTwoColumnsToRestaurants < ActiveRecord::Migration
  def change
    add_column :restaurants, :phone_number, :string
    add_column :restaurants, :picture_url, :string
  end
end
