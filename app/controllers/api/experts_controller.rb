module Api
  class ExpertsController < ApplicationController
    acts_as_token_authentication_handler_for User
    skip_before_action :verify_authenticity_token
    skip_before_filter :authenticate_user!

    def show
      @expert = Expert.find(params["id"].to_i)
      @recos = @expert.restaurants_recommended

    end

  end
end