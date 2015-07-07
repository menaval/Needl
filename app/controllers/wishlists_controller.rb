class WishlistsController < ApplicationController

  def index
    @wishlists = Wishlist.all
  end

  def create
    @wishlist = Wishlist.new(wishlist_params)
    render :new, notice: "Restaurant ajouté à ta wishlist"
  end

  private

  def wishlist_params
    params.require(:wishlist).permit(:user_id, :restaurant_id)
  end

end