class DropCorrespondences < ActiveRecord::Migration
  def change
    drop_table :correspondences
  end
end
