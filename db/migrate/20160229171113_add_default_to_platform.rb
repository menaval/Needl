class AddDefaultToPlatform < ActiveRecord::Migration
  def change
    change_column :users, :platform, :string, null: false, default: "ios"
  end
end
