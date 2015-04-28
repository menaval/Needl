class CreateRestaurantFoods < ActiveRecord::Migration
  def change
    create_table :restaurant_foods do |t|
      t.references :food, index: true
      t.references :restaurant, index: true

      t.timestamps null: false
    end
    add_foreign_key :restaurant_foods, :foods
    add_foreign_key :restaurant_foods, :restaurants
  end
end
