class RestaurantPerUser < ActiveRecord::Base
  belongs_to :restaurant
  belongs_to :user

  def number
    number = 0
    restaurant.recommendations.each do |reco|
      if user.my_friends.include?(User.find(reco.user_id))
        number += 1
      end
    end
    number
  end

  def get_ambiences_with_users
    restaurant.recommendations.each do |reco|
      if user.my_friends.include?(User.find(reco.user_id))
        reco.ambiences.each do |number|
          ambiences_list = ["chic", "festif", "typique", "en_cas_de_soleil", "fast_and_good"]
          ambience = ambiences_list[number.to_i - 1]
          hash[ambience] ||= []
          hash[ambience] << reco.user_id
        end
      end
    end
    hash.sort_by { |_name, ids| -ids.length }.first(2).to_h
  end

  def get_strengths_with_users
    restaurant.recommendations.each do |reco|
      if user.my_friends.include?(User.find(reco.user_id))
        reco.strengths.each do |number|
          ambiences_list = ["chic", "festif", "typique", "en_cas_de_soleil", "fast_and_good"]
          ambience = ambiences_list[number.to_i - 1]
          hash[ambience] ||= []
          hash[ambience] << reco.user_id
        end
      end
    end
    hash.sort_by { |_name, ids| -ids.length }.first(3).to_h
  end


end
