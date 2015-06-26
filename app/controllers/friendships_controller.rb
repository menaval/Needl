class FriendshipsController < ApplicationController


  def index
    @requests_received = User.where(id: current_user.my_requests_received_ids)
    @friends = User.where(id: current_user.my_friends_ids)
  end

  def new
    @friendship = Friendship.new
    @not_interested_relation = NotInterestedRelation.new
    @new_potential_friends = current_user.user_friends - User.where(id: current_user.my_friends_ids) - User.where(id: current_user.my_requests_sent_ids) - User.where(id: current_user.my_requests_received_ids) - User.where(id: current_user.refused_relations_ids) - [current_user]
  end

  def create
    @friendship = Friendship.new(friendship_params)
    @friendship.save
    redirect_to new_friendship_path
  end

  def invisible
    @friendship = Friendship.find(eval(params[:id])[:value])
    if @friendship.sender_id == current_user.id
      @friendship.update_attribute(:receiver_invisible, true)
    else
      @friendship.update_attribute(:sender_invisible, true)
    end
    redirect_to friendships_path
  end

  def visible
    @friendship = Friendship.find(eval(params[:id])[:value])
    if @friendship.sender_id == current_user.id
      @friendship.update_attribute(:receiver_invisible, false)
    else
      @friendship.update_attribute(:sender_invisible, false)
    end
    redirect_to friendships_path
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
      redirect_to friendships_path
    else
      friendship = Friendship.find(eval(params[:id])[:value])
      NotInterestedRelation.create(member_one_id: friendship.sender_id, member_two_id: friendship.receiver_id)
      friendship.destroy
      redirect_to new_friendship_path
    end
    # comprendre l'histoire de value qui n'y est pas suivant que ce soit un refuse ou un delete
  end

  private

    def friendship_params
      params.require(:friendship).permit(:sender_id, :receiver_id, :accepted)
    end

end
