class RecommendationsController < ApplicationController
  def index
    @recommendations = Recommendation.all
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

end
