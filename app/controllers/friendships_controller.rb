class FriendshipsController < ApplicationController

  def index
    @users = User.all
    @friendship = Friendship.new
    @friendships = current_user.friendships_by_status
    @not_interested_relation = NotInterestedRelation.new
    @new_potential_friends = @users - current_user.my_friends - current_user.pending_friends - current_user.refused_friends - [current_user]
  end

  def create
    @friendship = Friendship.new(friendship_params)
    @friendship.save
    redirect_to friendships_path
  end

  def answer_request
    @friendship = Friendship.find(eval(params[:id])[:value])
    status = eval(params[:accepted])[:value]
    if status == true
      @friendship.update_attribute(:accepted, true)
      flash[:notice] = 'Ami ajouté'
      redirect_to friendships_path
    else
      destroy
    end
  end

  def destroy
    @friendship = Friendship.find(eval(params[:id]))
    NotInterestedRelation.create(member_one_id: @friendship.sender_id, member_two_id: @friendship.receiver_id)
    @friendship.destroy
    redirect_to friendships_path, notice: "Vous n'êtes plus amis"
  end

  private

    def friendship_params
      params.require(:friendship).permit(:sender_id, :receiver_id, :accepted)
    end

end
