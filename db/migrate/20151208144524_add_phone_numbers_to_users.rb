class AddPhoneNumbersToUsers < ActiveRecord::Migration
  def change
    add_column  :users, :phone_numbers, :string, array: true, default: []
  end
end
