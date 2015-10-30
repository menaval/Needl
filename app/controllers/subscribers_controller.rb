class SubscribersController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def create
    @gibbon = Gibbon::Request.new(api_key: ENV['MAILCHIMP_API_KEY'])
    @list_id = ENV['MAILCHIMP_LIST_ID']

    @gibbon.lists(@list_id).members.create(
      body: {
        email_address: params["email"],
        status: "subscribed"
      }
    )
    redirect_to root_path(:subscribed => true)
  end

end