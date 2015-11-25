class AddNewsletterThemesSentToUser < ActiveRecord::Migration
  def change
    add_column :users, :newsletter_themes, :string, array: true
  end
end
