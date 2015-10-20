class AddExpertToRecommendations < ActiveRecord::Migration
  def change
    add_reference :recommendations, :expert, index: true
  end
end
