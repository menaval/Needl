class AddSubwaysToRestaurants < ActiveRecord::Migration
  def change
    add_column :restaurants, :subways_near, :string, array: true
  end
end
