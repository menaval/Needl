module Api
  class FollowershipsController < ApplicationController
    acts_as_token_authentication_handler_for User
    skip_before_action :verify_authenticity_token
    skip_before_filter :authenticate_user!

    def index
      @user = User.find_by(authentication_token: params["user_token"])
      @experts = Expert.all
    end

    def create
      @user = User.find_by(authentication_token: params["user_token"])
      @expert_id = params["expert_id"].to_i
      @followership = Followership.new(user_id: @user.id, expert_id: @expert_id )
      @followership.save
      # @tracker.track(@user.id, 'add_friend', { "user" => @user.name })
      # notif_friendship("invited")
      # redirect_to new_friendship_path, notice: "Votre demande d'invitation a bien été envoyée, vous pourrez accéder à ses recommandations dès lors qu'il vous acceptera"
      # ex: http://localhost:3000/api/friendships/new?friendship[sender_id]=40&friendship[receiver_id]=42&friendship[accepted]=false
      redirect_to followerships_path
    end

    def destroy
      @user = User.find_by(authentication_token: params["user_token"])
      @expert_id = params["expert_id"].to_i
      @followership = Followership.find_by(user_id: @user.id, expert_id: @expert_id )
      @followership.destroy
      redirect_to followerships_path
    end

  end
end