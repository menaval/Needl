class ChangeDefaultValueToSignUpCountInUsers < ActiveRecord::Migration
  def change
    change_column :users, :sign_in_count, :integer, :default => 1, :null => false
  end
end
