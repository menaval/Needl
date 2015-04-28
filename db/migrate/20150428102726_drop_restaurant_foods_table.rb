class DropRestaurantFoodsTable < ActiveRecord::Migration
  def up
    drop_table :restaurant_foods
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
