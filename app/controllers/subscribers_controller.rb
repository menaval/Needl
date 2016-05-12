class SubscribersController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def create
    @gibbon = Gibbon::Request.new(api_key: ENV['MAILCHIMP_API_KEY'])
    @list_id = ENV['MAILCHIMP_LIST_ID_WAITING_ANDROID']

    @array = []
    @gibbon.lists(@list_id).members.retrieve["members"].each do |user|
      @array << user["email_address"]
    end

    if @array.include?(params["email"]) == false
      @gibbon.lists(@list_id).members.create(
        body: {
          email_address: params["email"],
          status: "subscribed"
        }
      )

    end
    redirect_to root_path(:subscribed => true)
  end

  def login
    if current_user != nil
      if (Restaurant.where(id: params['restaurant_id'].to_i).length == 1)
        restaurant = Restaurant.find(params['restaurant_id'].to_i)

        if Wish.where(user_id: current_user.id, restaurant_id: restaurant.id).length > 0
          # already wishlisted
          redirect_to wish_failed_subscribers_path(message: 'already_wishlisted')
        elsif Recommendation.where(user_id: current_user.id, restaurant_id: restaurant.id).length > 0
          # already recommended
          redirect_to wish_failed_subscribers_path(message: 'already_recommended')
        else
          Wish.create(user_id: current_user.id, restaurant_id: restaurant.id)
          redirect_to wish_success_subscribers_path
        end
      else 
        redirect_to wish_failed_subscribers_path(message: 'restaurant_inexistant')
      end
    else
      @user = User.new

      if (Restaurant.where(id: params['restaurant_id'].to_i).length == 1)
        @restaurant = Restaurant.find(params['restaurant_id'].to_i)
        @picture = @restaurant.restaurant_pictures.first ? @restaurant.restaurant_pictures.first.picture : @restaurant.picture_url
      else 
        redirect_to wish_failed_subscribers_path(message: 'restaurant_inexistant')
      end
    end
  end

  def wish_success
    if current_user == nil
      redirect_to root_path
    end
  end

  def wish_failed
    if current_user == nil
      redirect_to root_path
    end

    if params['message'] == 'already_wishlisted'
      @message = 'Tu as déja ce restaurant sur ta wishlist'
    elsif params['message'] == 'already_recommended'
      @message = 'Tu as déja recommandé ce restaurant'
    elsif params['message'] == 'restaurant_inexistant'
      @message = 'Le restaurant que tu essaies de mettre sur ta wishlist n\'existe pas :\'('
    end
  end

end
