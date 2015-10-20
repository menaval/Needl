class AddAttachmentPictureToExperts < ActiveRecord::Migration
  def self.up
    change_table :experts do |t|
      t.attachment :picture
    end
  end

  def self.down
    remove_attachment :experts, :picture
  end
end
