class UsersController < ApplicationController
  require 'twilio-ruby'

  def show

    @user = User.find(params[:id])

  end

end
