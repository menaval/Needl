module Api
  class FriendshipsController < ApplicationController
    acts_as_token_authentication_handler_for User
    skip_before_action :verify_authenticity_token
    skip_before_filter :authenticate_user!
    respond_to :json

    def index
      @user = User.find_by(authentication_token: params["user_token"])
      @friends = User.where(id: @user.my_friends_ids).order(:name)
      @requests = User.where(id: @user.my_requests_received_ids)
      my_friends_and_me_ids = @user.my_friends_ids + @user.id

      recommendations_from_friends_and_me  = Recommendation.where(user_id: my_friends_and_me_ids)
      wishes_from_friends_and_me          = Wish.where(user_id: my_friends_and_me_ids)

      @friends_recommendations = {}
      recommendations_from_friends_and_me.each do |recommendation|
        @friends_recommendations[recommendation.user_id] ||= []
        @friends_recommendations[recommendation.user_id] << recommendation.id
      end

      @friends_wishes = {}
      wishes_from_friends_and_me.each do |wish|
        @friends_wishes[wish.user_id] ||= []
        @friends_wishes[wish.user_id] << wish.id
      end



      #  On répartit les amis dans les 3 catégories
      @category_1 = []
      @category_2 = []
      @category_3 = []

      TasteCorrespondence.where("member_one_id = ? or member_two_id = ?", @user.id, @user.id).each do |correspondence|

        member_one_id = correspondence.member_one_id
        member_two_id = correspondence.member_two_id
        if member_one_id == @user.id
          case correspondence.category
            when 1
              @category_1 << member_two_id
            when 2
              @category_2 << member_two_id
            when 3
              @category_3 << member_two_id
          end

        elsif member_two_id == @user.id
          case correspondence.category
            when 1
              @category_1 << member_one_id
            when 2
              @category_2 << member_one_id
            when 3
              @category_3 << member_one_id
          end
        end

      end


      # chercher une méthode 'automatique'
      if params["accepted"] == "false"
        create
      elsif params["accepted"] == "true"
        answer_yes
      elsif params["destroy"]
        @tracker.track(@user.id, 'refuse_or_delete_friend', { "user" => @user.name })
        destroy
      elsif params["invisible"]
        invisible
      elsif params["not_interested"]
        @tracker.track(@user.id, 'ignore_friend', { "user" => @user.name })
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

    # A supprimer

    def create
      @friend_id = params["friend_id"].to_i
      # en attendant de détruire complètement cette étape, on met accepted à true
      @friendship = Friendship.new(sender_id: @user.id, receiver_id: @friend_id, accepted: true)
      @friendship.save
      @tracker.track(@user.id, 'add_friend', { "user" => @user.name })
      notif_friendship("invited")
      redirect_to new_friendship_path, notice: "Votre demande d'invitation a bien été envoyée, vous pourrez accéder à ses recommandations dès lors qu'il vous acceptera"
      # ex: http://localhost:3000/api/friendships/new?friendship[sender_id]=40&friendship[receiver_id]=42&friendship[accepted]=false

    end

    # A supprimer

    def answer_yes
      @friend_id = params["friend_id"].to_i
      friendship = Friendship.where(sender_id: @friend_id, receiver_id: @user.id).first
      friendship.update_attribute(:accepted, true)
      @tracker.track(@user.id, 'accept_friend', { "user" => @user.name })
      notif_friendship("accepted")
      redirect_to friendships_path
    end

    def destroy
      # pour voir dans quelle sens s'est faite la relation sans avoir à le préciser dans l'url
      if Friendship.where(sender_id: params["friend_id"].to_i, receiver_id: @user.id).first
      friendship = Friendship.where(sender_id: params["friend_id"].to_i, receiver_id: @user.id).first
      NotInterestedRelation.create(member_one_id: params["friend_id"].to_i, member_two_id: @user.id)
    else
      friendship = Friendship.where(sender_id: @user.id, receiver_id: params["friend_id"].to_i).first
      NotInterestedRelation.create(member_one_id: @user.id, member_two_id: params["friend_id"].to_i)
    end
      friendship.destroy
      redirect_to friendships_path
      # gérer la redirection suivant un delete ou un ignore
    end

    def invisible
      invisible = params["invisible"]
      if Friendship.where(sender_id: params["friend_id"].to_i, receiver_id: @user.id).first
        friendship = Friendship.where(sender_id: params["friend_id"].to_i, receiver_id: @user.id).first
        friendship.update_attribute(:sender_invisible, invisible)
      else
        friendship = Friendship.where(sender_id: @user.id, receiver_id: params["friend_id"].to_i).first
        friendship.update_attribute(:receiver_invisible, invisible)
      end
      if invisible == true
        @tracker.track(@user.id, 'hide_friend', { "user" => @user.name })
      else
        @tracker.track(@user.id, 'unhide_friend', { "user" => @user.name })
      end
      redirect_to friendships_path
    end

    #  A supprimer

    def notif_friendship(status)

      client = Parse.create(application_id: ENV['PARSE_APPLICATION_ID'], api_key: ENV['PARSE_API_KEY'])
      # status: nouvelle demande ou accepté ?
      if status == "accepted"
        # envoyer à @friend qu'il a été accepté
        data = { :alert => "#{@user.name} a accepte votre invitation", :badge => 'Increment', :type => 'friend' }
        push = client.push(data)
        # push.type = "ios"
        query = client.query(Parse::Protocol::CLASS_INSTALLATION).eq('user_id', @friend_id)
        push.where = query.where
        push.save
      else
        # envoyer à @friend qu'on l'a invité
        data = { :alert => "#{@user.name} vous invite a decouvrir ses restaurants", :badge => 'Increment', :type => 'friend' }
        push = client.push(data)
        # push.type = "ios"
        query = client.query(Parse::Protocol::CLASS_INSTALLATION).eq('user_id', @friend_id)
        push.where = query.where
        push.save
      end

    end

    def not_interested
      NotInterestedRelation.create(member_one_id: @user.id, member_two_id: params["friend_id"])
      redirect_to new_friendship_path
    end

    # def friendship_params
    #   params.require(:friendship).permit(:sender_id, :receiver_id, :accepted)
    # end

    # je ne passe pas par les strong params à voir

  end
end