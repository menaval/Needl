module Api
  class FriendshipsController < ApplicationController
    acts_as_token_authentication_handler_for User
    skip_before_action :verify_authenticity_token
    skip_before_filter :authenticate_user!

    def index
      @user = User.find_by(authentication_token: params["user_token"])
      @friends = User.where(id: @user.my_friends_ids)
      @requests = User.where(id: current_user.my_requests_received_ids)
      # chercher une méthode 'automatique'
      if params["receiver_id"] && params["sender_id"] && params["accepted"]
        create
      end
    end

    def new
      @user = User.find_by(authentication_token: params["user_token"])
      @friendship = Friendship.new
      @not_interested_relation = NotInterestedRelation.new
      @new_potential_friends = current_user.user_friends - User.where(id: current_user.my_friends_ids) - User.where(id: current_user.my_requests_sent_ids) - User.where(id: current_user.my_requests_received_ids) - User.where(id: current_user.refused_relations_ids) - [current_user]

      if params["receiver_id"] && params["sender_id"] && params["accepted"]
        create
      end
    end

    def create
      @friendship = Friendship.new(sender_id: params["sender_id"], receiver_id: params["receiver_id"], accepted: params["accepted"])
      # pas terrible de creer sans un strong params ..
      @friendship.save
      render :new
    end

    private

    def friendship_params
      params.require(:friendship).permit(:sender_id, :receiver_id, :accepted)
    end

  end
end