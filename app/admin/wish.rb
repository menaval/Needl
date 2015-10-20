ActiveAdmin.register Wish do

  permit_params :restaurant_id, :user_id
  batch_action :wish_from_admin do |ids|
    Wish.find(ids).each do |wish|
      activity = PublicActivity::Activity.find_by(trackable_type: "Wish", trackable_id: wish.id)
      activity.owner_id = wish.user_id
      activity.save
    end
  redirect_to admin_wishes_path, alert: "Rendu à César !"
  end

end