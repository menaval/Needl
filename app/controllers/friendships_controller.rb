class FriendshipsController < ApplicationController

  def index
    @users = User.all
    @friendship = Friendship.new
    @friendships = current_user.friendships_by_status
    # enlever ceux qui ont été mis en not interested
    @new_potential_friends = @users - current_user.all_my_pending_and_accepted_friends - current_user.refused - [current_user]
  end

  def create
    @friendship = Friendship.new(friendship_params)
    @friendship.save
  end

  def answer_request
    @friendship = Friendship.find(eval(params[:id])[:value])
    status = eval(params[:accepted])[:value]
    if status == true
      @friendship.update_attribute(:accepted, true)
      flash[:notice] = 'Ami ajouté'
      redirect_to friendships_path
    else
      @friendship.update_attribute(:interested, false)
      flash[:notice] = 'Ami refusé'
      redirect_to friendships_path
    end
  end

  def unfriend
    @friendship = Friendship.find(eval(params[:id])[:value])
    @friendship.update_attribute(:interested, false)
    redirect_to friendships_path, notice: "Vous n'êtes plus amis"
  end

  private

    def friendship_params
      params.require(:friendship).permit(:sender_id, :receiver_id, :accepted, :interested)
    end

end
