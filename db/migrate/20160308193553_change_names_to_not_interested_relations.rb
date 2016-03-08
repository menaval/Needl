class ChangeNamesToNotInterestedRelations < ActiveRecord::Migration
  def change
    rename_column :not_interested_relations, :member_one_id, :refuser_id
    rename_column :not_interested_relations, :member_two_id, :refused_id
  end
end
