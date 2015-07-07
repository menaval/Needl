class CreateWishlists < ActiveRecord::Migration
  def change
    create_table :wishlists do |t|
      t.references :user, index: true
      t.references :restaurant, index: true

      t.timestamps null: false
    end
    add_foreign_key :wishlists, :users
    add_foreign_key :wishlists, :restaurants
  end
end
