class Recommendation < ActiveRecord::Base
  belongs_to :user
  belongs_to :restaurant
  validates :price, presence: true
  validates :strengths, presence: true
  validates :ambiences, presence: true
  # checker comment faire pour limiter le nombre d'ambiances que l'on peut remplir et comment rajouter cette liste dans la database
end
