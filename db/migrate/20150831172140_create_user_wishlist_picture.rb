class CreateUserWishlistPicture < ActiveRecord::Migration
  def change
    create_table :user_wishlist_pictures do |t|
      t.references :user, index: true

      t.timestamps null: false
    end
    add_foreign_key :user_wishlist_pictures, :users
  end
end
