class ChangeTypeToFriendshipsAccepted < ActiveRecord::Migration
  def change
    change_column :friendships, :accepted, 'boolean USING CAST(accepted AS boolean)'
  end
end
