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
    @activities = PublicActivity::Activity.order('created_at DESC').limit(20)
  end

  # def current_user
  #   @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  # end

  # helper_method :current_user
  # hide_action :current_user
end
