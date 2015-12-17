class AddNewsletterUpdatedToUsers < ActiveRecord::Migration
  def change
    add_column  :users, :newsletter_updated, :boolean, default: true
  end
end
