class DropFollowerships < ActiveRecord::Migration
  def up
    drop_table :followerships
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
