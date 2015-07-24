class AddWishlistToRecommendation < ActiveRecord::Migration
  def change
    add_column :recommendations, :wishlist, :boolean
  end
end
