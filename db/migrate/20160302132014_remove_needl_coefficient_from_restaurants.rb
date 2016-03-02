class RemoveNeedlCoefficientFromRestaurants < ActiveRecord::Migration
  def change
    remove_column :restaurants, :needl_coefficient, :integer
  end
end
