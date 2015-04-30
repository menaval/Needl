class UsersController < ApplicationController
  def show
  end

  def my_restaurant
    @restaurants = current_user.restaurants
  end

end
