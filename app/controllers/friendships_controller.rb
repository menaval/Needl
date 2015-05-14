class FriendshipsController < ApplicationController

  def new
    @users = current_user.user_friends
    @friendship = Friendship.new
    @friendships = current_user.friendships_by_status
    @not_interested_relation = NotInterestedRelation.new
    @new_potential_friends = @users - current_user.my_friends - current_user.pending_invitations_sent - current_user.pending_invitations_received - current_user.refused_friends - [current_user]
  end

  def create
    @friendship = Friendship.new(friendship_params)
    @friendship.save
    redirect_to new_friendship_path
  end

  def answer_request
    @friendship = Friendship.find(eval(params[:id])[:value])
    status = eval(params[:accepted])[:value]
    if status == true
      @friendship.update_attribute(:accepted, true)
      redirect_to new_friendship_path
    else
      destroy
    end
  end

  def destroy
    if eval(params[:id]).is_a? Integer
      friendship = Friendship.find(eval(params[:id]))
      NotInterestedRelation.create(member_one_id: friendship.sender_id, member_two_id: friendship.receiver_id)
      friendship.destroy
      redirect_to new_friendship_path
    else
      friendship = Friendship.find(eval(params[:id])[:value])
      NotInterestedRelation.create(member_one_id: friendship.sender_id, member_two_id: friendship.receiver_id)
      friendship.destroy
      redirect_to friendships_path
    end
    # comprendre l'histoire de value qui n'y est pas suivant que ce soit un refuse ou un delete
  end

  private

    def friendship_params
      params.require(:friendship).permit(:sender_id, :receiver_id, :accepted)
    end

end
