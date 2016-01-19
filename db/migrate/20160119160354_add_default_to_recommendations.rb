class AddDefaultToRecommendations < ActiveRecord::Migration
  def change
    change_column  :recommendations, :friends_thanking, :integer, array: true, null: false, default: []
    change_column  :recommendations, :contacts_thanking, :json, array: true, null: false, default: []
  end
end
