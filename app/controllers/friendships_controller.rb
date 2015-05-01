class FriendshipsController < ApplicationController
  before_action :set_friend, only: [:destroy, :answer_request]
  def index
    @users = User.all
    @friendship = Friendship.new
    @friendships = current_user.friendships_by_status
  end

  def create
    @friendship = Friendship.new(friendship_params)
    if @friendship.save
      flash[:notice] = 'request_sent'
      redirect_to friendships_path
    else
      flash[:notice] = 'request_not_sent'
      redirect_to friendships_path
    end
  end

  def answer_request
    status = params[:accepted]
    if status == "true"
      @friendship.accepted = true
      @friendship.save
      @friendship.sender.save
      @friendship.receiver.save
      flash[:notice] = 'accept_friend'
      redirect_to friendships_path
    else
      @friendship.destroy
      flash[:notice] = 'refuse_friend'
      redirect_to friendships_path
    end
  end

  def destroy
    friendship_id = params[:friendship_id]
    relation = Friendship.where("sender_id = ? or receiver_id = ?", current_user.id, current_user.id).where("sender_id = ? or receiver_id = ?",  friendship_id, friendship_id).first
    if relation.nil?
      redirect_to friendships_path, notice: "unknown relation"
    else
      relation.destroy
      redirect_to friendships_path, notice: "relation destroyed"
    end
  end

  private

    def set_friendship
      @friendship = Friendship.find(params[:id])
    end

    def friendship_params
      params.require(:friendship).permit(:sender_id, :receiver_id, :accepted)
    end
end
