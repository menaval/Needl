class AddSenderToFriendships < ActiveRecord::Migration
  def change
    add_column :friendships, :sender_invisible, :boolean, default: false
    add_column :friendships, :receiver_invisible, :boolean, default: false
  end
end
