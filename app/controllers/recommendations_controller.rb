class RecommendationsController < ApplicationController
  def index
    @recommendations = Recommendation.all
  end

  def new
    @recommendation = Recommendation.new
  end

  def create
    @recommendation = Recommendation.new(recommendation_params)
    @restaurant = Restaurant.find_by_name(params[:name])
    if @recommendation.save
      redirect_to restaurant_path(@restaurant.id)
    else
      render 'new'
    end
  end

  private

  def recommendation_params
    params.require(:recommendation).permit(:price, :review, :strengths, :ambiences)
  end

end
