class AddTablesToRestaurants < ActiveRecord::Migration
  def change
    add_column :restaurants, :starter1, :string
    add_column :restaurants, :starter2, :string
    add_column :restaurants, :price_starter1, :integer
    add_column :restaurants, :price_starter2, :integer
    add_column :restaurants, :main_course1, :string
    add_column :restaurants, :main_course2, :string
    add_column :restaurants, :main_course3, :string
    add_column :restaurants, :price_main_course1, :integer
    add_column :restaurants, :price_main_course2, :integer
    add_column :restaurants, :price_main_course3, :integer
    add_column :restaurants, :dessert1, :string
    add_column :restaurants, :dessert2, :string
    add_column :restaurants, :price_dessert1, :integer
    add_column :restaurants, :price_dessert2, :integer
  end
end
