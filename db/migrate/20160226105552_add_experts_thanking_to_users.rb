class AddExpertsThankingToUsers < ActiveRecord::Migration
  def change
    add_column  :recommendations, :experts_thanking, :integer, array: true, null: false, default: []
  end
end
