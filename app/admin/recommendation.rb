ActiveAdmin.register Recommendation do

  permit_params :ambiences, :strengths, :review, :price, :restaurant_id, :user_id, :price_ranges


end
