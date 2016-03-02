class AddNewsletterRestaurantsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :newsletter_restaurants, :integer, array: true, null: false, default: []
    remove_column :users, :newsletter_themes, :string, array: true
    add_column :users, :newsletter_themes, :integer, array: true, null: false, default: []
  end
end
