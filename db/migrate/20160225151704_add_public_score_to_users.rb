class AddPublicScoreToUsers < ActiveRecord::Migration
  def change
    add_column :users, :public_score, :integer, :default => 0
  end
end
