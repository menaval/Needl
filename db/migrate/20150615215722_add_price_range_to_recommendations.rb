class AddPriceRangeToRecommendations < ActiveRecord::Migration
  def change
    add_column :recommendations, :price_range, :string, array: true
  end
end
