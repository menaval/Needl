class AddAgeRangeToUsers < ActiveRecord::Migration
  def change
    add_column :users, :age_range, :string
  end
end
