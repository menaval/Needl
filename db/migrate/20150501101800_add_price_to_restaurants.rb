class AddPriceToRestaurants < ActiveRecord::Migration
  def change
    add_column :restaurants, :price, :integer, :default => 0
  end
end
