class FriendshipsController < ApplicationController


  def index
    @requests_received = User.where(id: current_user.my_requests_received_ids)
    @friends = User.where(id: current_user.my_friends_ids).order(:name)
  end

  def new
    @friendship = Friendship.new
    @not_interested_relation = NotInterestedRelation.new
    @new_potential_friends = current_user.user_friends - User.where(id: current_user.my_friends_ids) - User.where(id: current_user.my_requests_sent_ids) - User.where(id: current_user.my_requests_received_ids) - User.where(id: current_user.refused_relations_ids) - [current_user]
  end

  def create
    @friendship = Friendship.new(friendship_params)
    @friendship.save
    @friend_id = @friendship.receiver_id
    notif_friendship("invited")
    redirect_to new_friendship_path, notice: "Votre demande d'invitation a bien été envoyée, vous pourrez accéder à ses recommandations dès lors qu'il vous acceptera"
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
      @friend_id = @friendship.sender_id == current_user.id ? @friendship.receiver_id : @friendship.sender_id
      notif_friendship("accepted")
      redirect_to friendships_path
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

    def notif_friendship(status)

      client = Parse.create(application_id: ENV['PARSE_APPLICATION_ID'], api_key: ENV['PARSE_API_KEY'])
      # status: nouvelle demande ou accepté ?
      if status == "accepted"
        # envoyer à @friend qu'il a été accepté
        data = { :alert => "#{current_user.name} a accepte votre invitation" }
        push = client.push(data)
        push.type = "ios"
        query = client.query(Parse::Protocol::CLASS_INSTALLATION).eq('user_id', @friend_id)
        push.where = query.where
        push.save
      else
        # envoyer à @friend qu'on l'a invité
        data = { :alert => "#{current_user.name} vous a invite a decouvrir ses restaurants" }
        push = client.push(data)
        push.type = "ios"
        query = client.query(Parse::Protocol::CLASS_INSTALLATION).eq('user_id', @friend_id)
        push.where = query.where
        push.save
      end

    end

end
