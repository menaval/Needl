class FixColumnNameToFriendships < ActiveRecord::Migration
  def change
    rename_column :friendships, :status, :accepted
  end
end
