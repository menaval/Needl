module Api
  class FriendshipsController < ApplicationController
    acts_as_token_authentication_handler_for User
    skip_before_action :verify_authenticity_token
    skip_before_filter :authenticate_user!
    respond_to :json

    def index
      @user = User.find_by(authentication_token: params["user_token"])
      @friends = User.where(id: @user.my_friends_ids)
      @requests = User.where(id: @user.my_requests_received_ids)
      # chercher une méthode 'automatique'
      if params["friendship"]["accepted"] == "false"
        create
      elsif params["friendship"]["accepted"] == "true"
        answer_yes
      elsif params["destroy"]
        destroy
      elsif params["friendship"]["invisible"]
        invisible
      elsif params["not_interested"]
        not_interested
      end
    end

    def new
      @user = User.find_by(authentication_token: params["user_token"])
      @friendship = Friendship.new
      @not_interested_relation = NotInterestedRelation.new
      @new_potential_friends = @user.user_friends - User.where(id: @user.my_friends_ids) - User.where(id: @user.my_requests_sent_ids) - User.where(id: @user.my_requests_received_ids) - User.where(id: @user.refused_relations_ids) - [@user]
    end

    private

    def create
      @friendship = Friendship.new(friendship_params)
      @friendship.save
      redirect_to new_friendship_path, notice: "Votre demande d'invitation a bien été envoyée, vous pourrez accéder à ses recommandations dès lors qu'il vous acceptera"
      # ex: http://localhost:3000/api/friendships/new?friendship[sender_id]=40&friendship[receiver_id]=42&friendship[accepted]=false

    end

    def answer_yes
      friendship = Friendship.where(sender_id: params["friendship"]["friend_id"].to_i, receiver_id: @user.id).first
      friendship.update_attribute(:accepted, true)
      redirect_to friendships_path
    end

    def destroy
      # pour voir dans quelle sens s'est faite la relation sans avoir à le préciser dans l'url
      if Friendship.where(sender_id: params["friendship"]["friend_id"].to_i, receiver_id: @user.id).first
      friendship = Friendship.where(sender_id: params["friendship"]["friend_id"].to_i, receiver_id: @user.id).first
      NotInterestedRelation.create(member_one_id: params["friendship"]["friend_id"].to_i, member_two_id: @user.id)
    else
      friendship = Friendship.where(sender_id: @user.id, receiver_id: params["friendship"]["friend_id"].to_i).first
      NotInterestedRelation.create(member_one_id: @user.id, member_two_id: params["friendship"]["friend_id"].to_i)
    end
      friendship.destroy
      redirect_to friendships_path
      # gérer la redirection suivant un delete ou un ignore
    end

    def invisible
      invisible = params["friendship"]["invisible"]
      if Friendship.where(sender_id: params["friendship"]["friend_id"].to_i, receiver_id: @user.id).first
        friendship = Friendship.where(sender_id: params["friendship"]["friend_id"].to_i, receiver_id: @user.id).first
        friendship.update_attribute(:sender_invisible, invisible)
      else
        friendship = Friendship.where(sender_id: @user.id, receiver_id: params["friendship"]["friend_id"].to_i).first
        friendship.update_attribute(:receiver_invisible, invisible)
      end
      redirect_to friendships_path
    end

    def not_interested
      NotInterestedRelation.create(member_one_id: @user.id, member_two_id: params["friendship"]["friend_id"])
      redirect_to new_friendship_path
    end

    def friendship_params
      params.require(:friendship).permit(:sender_id, :receiver_id, :accepted)
    end

  end
end