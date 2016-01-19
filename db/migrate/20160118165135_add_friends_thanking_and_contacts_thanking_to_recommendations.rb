class AddFriendsThankingAndContactsThankingToRecommendations < ActiveRecord::Migration
  def change
    add_column  :recommendations, :friends_thanking, :integer, array: true
    add_column  :recommendations, :contacts_thanking, :json, array: true
  end
end
