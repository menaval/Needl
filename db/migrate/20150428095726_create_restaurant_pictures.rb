class CreateRestaurantPictures < ActiveRecord::Migration
  def change
    create_table :restaurant_pictures do |t|
      t.references :restaurant, index: true

      t.timestamps null: false
    end
    add_foreign_key :restaurant_pictures, :restaurants
  end
end
