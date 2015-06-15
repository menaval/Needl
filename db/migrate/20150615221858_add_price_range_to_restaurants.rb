class AddPriceRangeToRestaurants < ActiveRecord::Migration
  def change
    add_column :restaurants, :price_range, :integer
  end
end
