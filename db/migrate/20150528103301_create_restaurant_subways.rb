class CreateRestaurantSubways < ActiveRecord::Migration
  def change
    create_table :restaurant_subways do |t|
      t.references :subway, index: true
      t.references :restaurant, index: true

      t.timestamps null: false
    end
  end
end
