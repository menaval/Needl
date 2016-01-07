class AddAppVersionToUsers < ActiveRecord::Migration
  def change
    add_column  :users, :app_version, :string
  end
end
