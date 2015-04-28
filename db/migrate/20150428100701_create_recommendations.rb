class CreateRecommendations < ActiveRecord::Migration
  def change
    create_table :recommendations do |t|
      t.integer :price
      t.string :review
      t.string :strengths, array: true
      t.string :ambiences, array: true
      t.references :user, index: true
      t.references :restaurant, index: true

      t.timestamps null: false
    end
    add_foreign_key :recommendations, :users
    add_foreign_key :recommendations, :restaurants
  end
end
