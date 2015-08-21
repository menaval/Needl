class AddFoodAndSubwayToRestaurants < ActiveRecord::Migration
  def change
    add_column :restaurants, :food_name, :string
    add_column :restaurants, :subway_id, :integer
    add_column :restaurants, :subway_name, :string
  end
end
