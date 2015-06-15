class AddPriceRangesToRecommendations < ActiveRecord::Migration
  def change
    add_column :recommendations, :price_ranges, :string, array: true
  end
end
