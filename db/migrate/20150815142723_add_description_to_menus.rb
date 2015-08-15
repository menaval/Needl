class AddDescriptionToMenus < ActiveRecord::Migration
  def change
    add_column :restaurants, :description_starter1, :string
    add_column :restaurants, :description_starter2, :string
    add_column :restaurants, :description_main_course1, :string
    add_column :restaurants, :description_main_course2, :string
    add_column :restaurants, :description_main_course3, :string
    add_column :restaurants, :description_dessert1, :string
    add_column :restaurants, :description_dessert2, :string
  end
end
