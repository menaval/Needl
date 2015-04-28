class CreateFriendships < ActiveRecord::Migration
  def change
    create_table :friendships do |t|
      t.string :status
      t.integer :receiver_id
      t.integer :sender_id

      t.timestamps null: false
    end
  end
end
