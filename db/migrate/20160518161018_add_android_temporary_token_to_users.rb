class AddAndroidTemporaryTokenToUsers < ActiveRecord::Migration
  def change
    add_column :users, :android_temporary_token, :string
  end
end
