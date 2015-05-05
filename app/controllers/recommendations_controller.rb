class RecommendationsController < ApplicationController
  include PublicActivity::StoreController
  before_action :load_activities, only: [:index, :new, :edit]

  def index
    @recommendations = Recommendation.all
    @friendships = current_user.friendships_by_status
  end

  def new
    @recommendation = Recommendation.new
  end

  def create
    @recommendation = current_user.recommendations.new(recommendation_params)
    if @recommendation.save
      @recommendation.restaurant.recompute_price(@recommendation)
      redirect_to restaurant_path(params[:recommendation][:restaurant_id])
    else
      render 'new'
    end
  end

  private

  def recommendation_params
    params.require(:recommendation).permit(:price, :review, { strengths: [] }, { ambiences: [] }, :restaurant_id)
  end

  def load_activities
    @activities = PublicActivity::Activity.where(owner_id: current_user.my_friends.map(&:id), owner_type: 'User').order('created_at DESC').limit(20)
  end

end
