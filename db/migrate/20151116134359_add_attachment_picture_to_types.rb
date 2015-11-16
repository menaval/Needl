class AddAttachmentPictureToTypes < ActiveRecord::Migration
  def self.up
    change_table :types do |t|
      t.attachment :picture
    end
  end

  def self.down
    remove_attachment :types, :picture
  end
end
