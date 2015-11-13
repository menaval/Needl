class SubscribersController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def create
    @gibbon = Gibbon::Request.new(api_key: ENV['MAILCHIMP_API_KEY'])
    @list_id = ENV['MAILCHIMP_LIST_ID_WAITING_ANDROID']

    @array = []
    @gibbon.lists(@list_id).members.retrieve["members"].each do |user|
      @array << user["email_address"]
    end

    if @array.include?(params["email"]) == false
      @gibbon.lists(@list_id).members.create(
        body: {
          email_address: params["email"],
          status: "subscribed"
        }
      )

    end
    redirect_to root_path(:subscribed => true)
  end

end
