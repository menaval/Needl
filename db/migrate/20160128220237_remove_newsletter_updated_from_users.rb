class RemoveNewsletterUpdatedFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :newsletter_updated, :boolean
  end
end
