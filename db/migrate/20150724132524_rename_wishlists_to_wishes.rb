class RenameWishlistsToWishes < ActiveRecord::Migration
  def change
    rename_table :wishlists, :wishes
  end
end
