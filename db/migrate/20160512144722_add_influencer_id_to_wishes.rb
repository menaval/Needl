class AddInfluencerIdToWishes < ActiveRecord::Migration
  def change
    add_column :wishes, :influencer_id, :integer
  end
end
