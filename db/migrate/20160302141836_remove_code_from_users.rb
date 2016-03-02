class RemoveCodeFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :code, :string
  end
end
