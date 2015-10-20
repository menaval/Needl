ActiveAdmin.register Recommendation do

  permit_params :ambiences, :strengths, :review, :restaurant_id, :user_id, :price_ranges, :expert_id

  batch_action :reco_from_expert do |ids|
    Recommendation.find(ids).each do |recommendation|
      activity = PublicActivity::Activity.find_by(trackable_type: "Recommendation", trackable_id: recommendation.id)
      activity.owner_id = recommendation.expert_id
      activity.owner_type = "Expert"
      activity.save
    end
  redirect_to admin_recommendations_path, alert: "Expertise tamponnée !"
  end

end
