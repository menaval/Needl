class ChangeScoreTypeToUsers < ActiveRecord::Migration
  def change
    change_column :users, :score, :integer, null: false, default: 0
  end
end
