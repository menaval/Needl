class AddDefaultToDescriptionUsers < ActiveRecord::Migration
  def change
    change_column :users, :description, :string, null: false, default: ""
  end
end
