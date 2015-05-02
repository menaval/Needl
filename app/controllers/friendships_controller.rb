class FriendshipsController < ApplicationController

  def index
    @users = User.all
    @friendship = Friendship.new
    @friendships = current_user.friendships_by_status
    # enlever ceux qui ont été mis en not interested
    @new_potential_friends = @users - current_user.all_my_pending_and_accepted_friends - [current_user]
  end

  def create
    @friendship = Friendship.new(friendship_params)
    if @friendship.save
      flash[:notice] = "Votre demande a bien été envoyée"
      redirect_to friendships_path
    else
      flash[:notice] = "Nous n'avons pas pu envoyer votre demande"
      redirect_to friendships_path
    end
  end

  def answer_request
    @friendship = Friendship.find(eval(params[:id])[:value])
    status = eval(params[:accepted])[:value]
    if status == true
      @friendship.update_attribute(:accepted, true)
      flash[:notice] = 'Ami ajouté'
      redirect_to friendships_path
    else
      @friendship.destroy
      flash[:notice] = 'Ami refusé'
      redirect_to friendships_path
    end
  end

  def destroy
    @friendship = Friendship.find(eval(params[:id]))
    if @friendship.nil?
      redirect_to friendships_path, notice: "unknown relation"
    else
      @friendship.update_attribute(:interested, false)
      redirect_to friendships_path, notice: "relation destroyed"
    end
  end

  def not_interested
    @friendship = Friendship.new(friendship_params)
    @friendship.update_attribute(:interested, params(:interested))
  end

  private

    def friendship_params
      params.require(:friendship).permit(:sender_id, :receiver_id, :accepted, :interested)
    end
end
