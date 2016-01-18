class CreateTasteCorrespondences < ActiveRecord::Migration
  def change
    create_table :taste_correspondences do |t|
      t.integer :member_one_id
      t.integer :member_two_id
      t.integer :number_of_shared_restaurants
      t.integer :category

      t.timestamps null: false
    end
  end
end
