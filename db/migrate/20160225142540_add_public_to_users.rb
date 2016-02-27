class AddPublicToUsers < ActiveRecord::Migration
  def change
    add_column :users, :public, :boolean, :default => false
    add_column :users, :description, :string
    add_column :users, :tags, :string, array: true
  end
end
