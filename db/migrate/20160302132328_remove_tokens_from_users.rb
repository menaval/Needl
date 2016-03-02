class RemoveTokensFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :code, :string
    remove_column :users, :tokens, :json
  end
end
