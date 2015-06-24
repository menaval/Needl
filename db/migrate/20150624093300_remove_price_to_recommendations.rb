class RemovePriceToRecommendations < ActiveRecord::Migration
  def change
    remove_column :recommendations, :price, :integer
  end
end
