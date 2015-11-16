class RemoveExpertIdFromRecommendations < ActiveRecord::Migration
  def change
    remove_column :recommendations, :expert_id, :integer
  end
end
