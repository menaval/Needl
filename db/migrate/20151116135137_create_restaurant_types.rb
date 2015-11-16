class CreateRestaurantTypes < ActiveRecord::Migration
  def change
    create_table :restaurant_types do |t|
      t.references :restaurant, index: true
      t.references :type, index: true

      t.timestamps null: false
    end
    add_foreign_key :restaurant_types, :restaurants
    add_foreign_key :restaurant_types, :types
  end
end
