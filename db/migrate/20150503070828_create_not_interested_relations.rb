class CreateNotInterestedRelations < ActiveRecord::Migration
  def change
    create_table :not_interested_relations do |t|
      t.integer :member_one_id
      t.integer :member_two_id

      t.timestamps null: false
    end
  end
end
