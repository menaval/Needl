class CreateImportedContacts < ActiveRecord::Migration
  def change
    create_table :imported_contacts do |t|
      t.references :user, index: true
      t.json :list
      t.boolean :imported, default: false

      t.timestamps null: false
    end
    add_foreign_key :imported_contacts, :users
  end
end
