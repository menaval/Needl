class DropExperts < ActiveRecord::Migration
  def up
    drop_table :experts
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
