ActiveAdmin.register Recommendation do

  permit_params :ambiences, :strengths, :review, :restaurant_id, :user_id, :price_ranges

end
