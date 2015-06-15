class Recommendation < ActiveRecord::Base
  include PublicActivity::Model
  belongs_to :user
  belongs_to :restaurant
  validates :strengths, presence: true
  validates :ambiences, presence: true
  validates :price_ranges, presence: true
  has_many :activities, as: :trackable, class_name: 'PublicActivity::Activity', dependent: :destroy
  tracked owner: Proc.new { |controller, _model| controller.current_user }, only: [:create, :update]
end
