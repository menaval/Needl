class AddFoursquareToRestaurants < ActiveRecord::Migration
  def change
    add_column  :restaurants, :foursquare_id, :string
    add_column  :restaurants, :foursquare_rating, :float
  end
end
