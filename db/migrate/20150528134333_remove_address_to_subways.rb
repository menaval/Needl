class RemoveAddressToSubways < ActiveRecord::Migration
  def change
    remove_column :subways, :address, :string
  end
end
