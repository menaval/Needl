class AddEmailsToUsers < ActiveRecord::Migration
  def change
    add_column  :users, :emails, :string, array: true, default: [], null: false
  end
end
