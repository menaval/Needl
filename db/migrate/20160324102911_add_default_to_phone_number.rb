class AddDefaultToPhoneNumber < ActiveRecord::Migration
  def change
    change_column :restaurants, :phone_number, :string, null: false, default: ""
  end
end
