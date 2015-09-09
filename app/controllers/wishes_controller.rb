class WishesController < ApplicationController

  def create
    if Wish.where(restaurant_id:params["wish"]["restaurant_id"].to_i, user_id: current_user.id).any?
    redirect_to restaurants_path, notice: "Restaurant déjà sur ta wishlist"
    else
      @wish = Wish.create(wish_params)
      redirect_to :back, notice: "Restaurant ajouté à ta wishlist"
    end
  end

  def destroy
    wish = Wish.find(params[:id])
    # certains wish ont été crée avant qu'il n'y ait eu de publicActivity s'appliquant à eux
    if PublicActivity::Activity.where(trackable_type: "Wish", trackable_id: wish.id).length > 0
      activity = PublicActivity::Activity.where(trackable_type: "Wish", trackable_id: wish.id).first
      activity.destroy
    end
    wish.destroy
    redirect_to :back, notice: 'Le restaurant a bien été retiré de votre wishlist'
  end

  private

  def wish_params
    params.require(:wish).permit(:user_id, :restaurant_id)
  end

end