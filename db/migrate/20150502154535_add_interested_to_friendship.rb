class AddInterestedToFriendship < ActiveRecord::Migration
  def change
    add_column :friendships, :interested, :boolean, default: true
  end
end
