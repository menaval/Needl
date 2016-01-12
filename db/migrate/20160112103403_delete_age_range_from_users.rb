class DeleteAgeRangeFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :age_range, :string
  end
end
