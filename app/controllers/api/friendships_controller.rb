module Api
  class FriendshipsController < ApplicationController
    acts_as_token_authentication_handler_for User
    skip_before_action :verify_authenticity_token
    skip_before_filter :authenticate_user!
    respond_to :json

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

      if params["friendship"]
        create
      end
    end

    def create
      respond_with Friendship.create(friendship_params)

      # ex: http://localhost:3000/api/friendships/new?friendship[sender_id]=40&friendship[receiver_id]=42&friendship[accepted]=false

    end

    private

    def friendship_params
      params.require(:friendship).permit(:sender_id, :receiver_id, :accepted)
    end

  end
end