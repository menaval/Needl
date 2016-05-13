class Recommendation < ActiveRecord::Base
  include PublicActivity::Model
  belongs_to :user
  belongs_to :restaurant
  attr_accessor :wish
  has_many :activities, as: :trackable, class_name: 'PublicActivity::Activity', dependent: :destroy
end
