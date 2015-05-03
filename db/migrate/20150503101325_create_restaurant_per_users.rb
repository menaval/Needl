class CreateRestaurantPerUsers < ActiveRecord::Migration
  def change
    create_table :restaurant_per_users do |t|
      t.references :restaurant, index: true
      t.references :user, index: true
      t.string :strengths, array: true
      t.string :ambiences, array: true

      t.timestamps null: false
    end
    add_foreign_key :restaurant_per_users, :restaurants
    add_foreign_key :restaurant_per_users, :users
  end
end
