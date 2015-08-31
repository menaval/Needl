class AddAttachmentPictureToUserWishlistPictures < ActiveRecord::Migration
  def self.up
    change_table :user_wishlist_pictures do |t|
      t.attachment :picture
    end
  end

  def self.down
    remove_attachment :user_wishlist_pictures, :picture
  end
end
