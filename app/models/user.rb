class User < ActiveRecord::Base

  has_many :recommendations, dependent: :destroy

  has_many :friendships, foreign_key: :sender_id, dependent: :destroy
  has_many :received_friendships, foreign_key: :receiver_id, class_name: 'Friendship', dependent: :destroy

  has_many :not_interested_relations, foreign_key: :member_two_id, dependent: :destroy
  has_many :received_not_interested_relations, foreign_key: :member_one_id, class_name: 'NotInterestedRelation', dependent: :destroy

  has_many :senders, :through => :received_friendships, dependent: :destroy
  has_many :receivers, :through => :friendships, dependent: :destroy

  has_many :member_ones, :through => :not_interested_relations, dependent: :destroy
  has_many :member_twos, :through => :received_not_interested_relations, dependent: :destroy


  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :omniauth_providers => [ :facebook ]

  has_attached_file :picture,
      styles: { large: "800x800", medium: "300x300>", thumb: "50x50#" }
    validates_attachment_content_type :picture,
      content_type: /\Aimage\/.*\z/

  def my_friends
    user_ids = self.receivers.includes(:received_friendships).where(friendships: { accepted: true }).pluck(:id)
    user_ids += self.senders.includes(:friendships).where(friendships: { accepted: true }).pluck(:id)

    User.where(id: user_ids)
  end

  def my_visible_friends
    my_visible_friends_ids
    User.where(id: @user_ids)
  end

  def my_visible_friends_ids
    @user_ids = self.receivers.includes(:received_friendships).where(friendships: { accepted: true, receiver_invisible: false }).pluck(:id)
    @user_ids += self.senders.includes(:friendships).where(friendships: { accepted: true, sender_invisible: false }).pluck(:id)
  end

  def my_visible_friends_and_me
    user_ids = self.receivers.includes(:received_friendships).where(friendships: { accepted: true, receiver_invisible: false }).pluck(:id)
    user_ids += self.senders.includes(:friendships).where(friendships: { accepted: true, sender_invisible: false }).pluck(:id)
    user_ids += [self.id]

    User.where(id: user_ids).order(:name)
  end

  def pending_invitations_received
    user_ids = self.senders.includes(:friendships).where(friendships: { accepted: false }).pluck(:id)
    User.where(id: user_ids)
  end

  def pending_invitations_sent
    user_ids = self.receivers.includes(:received_friendships).where(friendships: { accepted: false }).pluck(:id)
    User.where(id: user_ids)
  end

  def refused_friends
    user_ids = self.member_ones.pluck(:id)
    user_ids += self.member_twos.pluck(:id)
    User.where(id: user_ids)
  end

  def user_friends
    graph = Koala::Facebook::API.new(self.token)
    friends_uids = graph.get_connections("me", "friends").map { |friend| friend["id"] }
    User.where(uid: friends_uids)
  end

  def my_friends_restaurants
    user_ids = my_visible_friends.map(&:id) + [self.id]
    Restaurant.joins(:recommendations).where(recommendations: { user_id: user_ids })
  end

  def my_friends_foods
    Food.joins(restaurants: :recommendations).where(recommendations: {user_id: my_visible_friends_ids}).uniq
  end

  def self.find_for_facebook_oauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.provider = auth.provider
      user.uid = auth.uid
      user.gender = auth.extra.raw_info.gender
      user.age_range = auth.extra.raw_info.age_range.min[1]
      if auth.info.email.nil?
        user.email = ""
      else
        user.email = auth.info.email
      end
      user.password = Devise.friendly_token[0,20]
      user.name = auth.info.name
      user.picture = auth.info.image.gsub('http://','https://') + "?width=1000&height=1000"
      user.token = auth.credentials.token
      user.token_expiry = Time.at(auth.credentials.expires_at)
    end
  end
end
