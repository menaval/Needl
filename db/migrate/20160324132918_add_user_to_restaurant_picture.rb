class AddUserToRestaurantPicture < ActiveRecord::Migration
  def change
    add_column :restaurant_pictures, :user_id, :integer
  end
end
