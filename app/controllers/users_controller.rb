class UsersController < ApplicationController
  def show
  end

  def update

  end

  def my_restaurant
    @restaurants = current_user.restaurants
  end

end
