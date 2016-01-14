class Recommendation < ActiveRecord::Base
  include PublicActivity::Model
  belongs_to :user
  belongs_to :restaurant
  validates :strengths, presence: true
  validates :ambiences, presence: true

  # On garde pour l'instant sans les occasions pour l'ancienne version
  # validates :occasions, presence: true
  attr_accessor :wish
  has_many :activities, as: :trackable, class_name: 'PublicActivity::Activity', dependent: :destroy
  tracked owner: Proc.new { |controller, _model| controller.current_user }, only: [:create]
end
