class AddFoodToRestaurants < ActiveRecord::Migration
  def change
    add_reference :restaurants, :food, index: true
    add_foreign_key :restaurants, :foods
  end
end
