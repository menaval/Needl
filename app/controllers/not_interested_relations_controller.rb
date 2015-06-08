class NotInterestedRelationsController < ApplicationController

  def create
    @not_interested_relation = NotInterestedRelation.new(not_interested_relation_params)
    @not_interested_relation.save
    redirect_to new_friendship_path
  end

  private

  def not_interested_relation_params
    params.require(:not_interested_relation).permit(:member_one_id, :member_two_id)
  end

end