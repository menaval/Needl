ActiveAdmin.register Recommendation do

  permit_params :ambiences, :strengths, :review, :restaurant_id, :user_id, :price_ranges, :expert_id

  batch_action :reco_from_expert do |ids|
    Recommendation.find(ids).each do |recommendation|
      activity = PublicActivity::Activity.find_by(trackable_type: "Recommendation", trackable_id: recommendation.id)
      expert = Expert.find(recommendation.expert_id)
      restaurant = Restaurant.find(recommendation.restaurant_id)
      activity.owner_id = expert.id
      activity.owner_type = "Expert"
      activity.save

      #  envoie des notifs

    client = Parse.create(application_id: ENV['PARSE_APPLICATION_ID'], api_key: ENV['PARSE_API_KEY'], master_key:ENV['PARSE_MASTER_KEY'])
      # envoyer à tous les followers que l'expert a fait une nouvelle reco du resto @restaurant
      data = { :alert => "#{expert.name} a recommande #{restaurant.name}", :badge => 'Increment', :type => 'reco'  }
      push = client.push(data)
      # push.type = "ios"
      query = client.query(Parse::Protocol::CLASS_INSTALLATION).value_in('user_id', expert.followers.pluck(:id))
      push.where = query.where
      push.save

    end

  redirect_to admin_recommendations_path, alert: "Expertise tamponnée !"
  end

end
