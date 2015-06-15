class DeletePriceRangeRecommendations < ActiveRecord::Migration
  def change
    remove_column :recommendations, :price_range
  end
end
