class CreateExperts < ActiveRecord::Migration
  def change
    create_table :experts do |t|
      t.string :name

      t.timestamps null: false
    end
  end
end
