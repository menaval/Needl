module Api
  class FollowershipsController < ApplicationController
    acts_as_token_authentication_handler_for User
    skip_before_action :verify_authenticity_token
    skip_before_filter :authenticate_user!

#  quel endpoint ?
    def create
      @expert_id = params["expert_id"].to_i
      @user = User.find_by(authentication_token: params["user_token"])
      @followership = Followership.new(user_id: @user.id, expert_id: @expert_id )
      @followership.save
      # @tracker.track(@user.id, 'add_friend', { "user" => @user.name })
      # notif_friendship("invited")
      # redirect_to new_friendship_path, notice: "Votre demande d'invitation a bien été envoyée, vous pourrez accéder à ses recommandations dès lors qu'il vous acceptera"
      # ex: http://localhost:3000/api/friendships/new?friendship[sender_id]=40&friendship[receiver_id]=42&friendship[accepted]=false

    end

  end
end