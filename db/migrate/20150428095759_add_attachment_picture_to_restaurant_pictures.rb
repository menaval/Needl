class AddAttachmentPictureToRestaurantPictures < ActiveRecord::Migration
  def self.up
    change_table :restaurant_pictures do |t|
      t.attachment :picture
    end
  end

  def self.down
    remove_attachment :restaurant_pictures, :picture
  end
end
