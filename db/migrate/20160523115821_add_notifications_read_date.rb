class AddNotificationsReadDate < ActiveRecord::Migration
  def change
    add_column :users, :notifications_read_date, :datetime
  end
end
