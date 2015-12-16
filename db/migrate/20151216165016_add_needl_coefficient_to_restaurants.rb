class AddNeedlCoefficientToRestaurants < ActiveRecord::Migration
  def change
    add_column  :restaurants, :needl_coefficient, :integer, default: 0
  end
end
