class AddOccasionsToRecommendations < ActiveRecord::Migration
  def change
    add_column :recommendations, :occasions, :string, array: true
  end
end
