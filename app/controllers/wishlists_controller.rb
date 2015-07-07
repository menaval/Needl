class WishlistsController < ApplicationController

  def index
    @wishlists = Wishlist.all
  end

  def create
    if Wishlist.where(restaurant_id:params["wishlist"]["restaurant_id"].to_i, user_id: current_user.id).any?
    redirect_to restaurants_path, notice: "Restaurant déjà sur ta wishlist"
    else
      @wishlist = Wishlist.create(wishlist_params)
      redirect_to restaurants_path, notice: "Restaurant ajouté à ta wishlist"
    end
  end

  private

  def wishlist_params
    params.require(:wishlist).permit(:user_id, :restaurant_id)
  end

end