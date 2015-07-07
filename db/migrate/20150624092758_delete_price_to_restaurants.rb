class DeletePriceToRestaurants < ActiveRecord::Migration
  def change
    remove_column :restaurants, :price, :integer
  end
end
