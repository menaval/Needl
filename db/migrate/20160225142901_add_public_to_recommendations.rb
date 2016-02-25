class AddPublicToRecommendations < ActiveRecord::Migration
  def change
    add_column :recommendations, :public, :boolean, :default => false
    add_column :recommendations, :url, :string
  end
end
