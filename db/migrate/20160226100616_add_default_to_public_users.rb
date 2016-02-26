class AddDefaultToPublicUsers < ActiveRecord::Migration
  def change
    change_column :users, :description, :string, default: ""
    change_column :users, :tags, :string, array: true, null: false, default: []
  end
end
