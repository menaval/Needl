class CreateFollowerships < ActiveRecord::Migration
  def change
    create_table :followerships do |t|
      t.references :user, index: true
      t.references :expert, index: true

      t.timestamps null: false
    end
    add_foreign_key :followerships, :users
    add_foreign_key :followerships, :experts
  end
end
