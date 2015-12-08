class User < ActiveRecord::Base
  after_create :send_welcome_email

  acts_as_token_authenticatable
  has_many :recommendations, dependent: :destroy
  has_many :wishes, dependent: :destroy

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
         :omniauthable, :omniauth_providers => [ :facebook, :facebook_access_token ]

  has_attached_file :picture,
      styles: { large: "800x800", medium: "300x300>", thumb: "50x50#" }
    validates_attachment_content_type :picture,
      content_type: /\Aimage\/.*\z/

  def my_friends_ids
    user_ids = self.receivers.includes(:received_friendships).where(friendships: { accepted: true }).pluck(:id)
    user_ids += self.senders.includes(:friendships).where(friendships: { accepted: true }).pluck(:id)
    user_ids.uniq
  end

  def my_friends_seing_me_ids
    @user_ids = self.receivers.includes(:received_friendships).where(friendships: { accepted: true, sender_invisible: false }).pluck(:id)
    @user_ids += self.senders.includes(:friendships).where(friendships: { accepted: true, receiver_invisible: false }).pluck(:id)
    @user_ids.uniq
  end

  def my_visible_friends_ids
    @user_ids = self.receivers.includes(:received_friendships).where(friendships: { accepted: true, receiver_invisible: false }).pluck(:id)
    @user_ids += self.senders.includes(:friendships).where(friendships: { accepted: true, sender_invisible: false }).pluck(:id)
    @user_ids.uniq
  end

  def my_visible_friends_ids_and_me
    @user_ids = self.receivers.includes(:received_friendships).where(friendships: { accepted: true, receiver_invisible: false }).pluck(:id)
    @user_ids += self.senders.includes(:friendships).where(friendships: { accepted: true, sender_invisible: false }).pluck(:id)
    @user_ids += [self.id]
    @user_ids.uniq
  end

  def my_requests_received_ids
    user_ids = self.senders.includes(:friendships).where(friendships: { accepted: false }).pluck(:id)
  end

  def my_requests_sent_ids
    user_ids = self.receivers.includes(:received_friendships).where(friendships: { accepted: false }).pluck(:id)
  end

  def refused_relations_ids
    user_ids = self.member_ones.pluck(:id)
    user_ids += self.member_twos.pluck(:id)
  end

  def my_friends_restaurants_ids
    user_ids = my_visible_friends_ids
    restos_ids = Restaurant.joins(:recommendations).where(recommendations: { user_id: user_ids }).pluck(:id).uniq
  end

  def my_restaurants_ids
    restos_ids = Restaurant.joins(:recommendations).where(recommendations: { user_id: self.id }).pluck(:id)
    restos_ids += Restaurant.joins(:wishes).where(wishes: {user_id: self.id}).pluck(:id)
    # Restaurant.joins(:recommendations, :wishes).where("recommendations.user_id = ? OR wishes.user_id = ?", self.id, self.id)
    # pas performant comme code, 3 appels
  end

  def my_recos
    Restaurant.joins(:recommendations).where(recommendations: { user_id: self.id })
  end

  def my_wishes
    Restaurant.joins(:wishes).where(wishes: {user_id: self.id})
  end

  def my_friends_foods
    Food.joins(restaurants: :recommendations).where(recommendations: {user_id: my_visible_friends_ids}).uniq
  end

  def my_friends_subways
    Subway.joins(:restaurant_subways).includes(restaurants: :recommendations).where(recommendations: {user_id: self.my_visible_friends_ids + [self.id]}).uniq
  end


  def user_friends
    graph = Koala::Facebook::API.new(self.token)
    friends_uids = graph.get_connections("me", "friends").map { |friend| friend["id"] }
    User.where(uid: friends_uids)
  end

  def self.find_for_facebook_oauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      puts "______________________________________________________________________"
      puts "#{auth}"
      user.provider = auth.provider
      puts "provider: #{auth.provider}"
      user.uid = auth.uid
      puts "uid: #{auth.uid}"
      user.gender = auth.extra.raw_info.gender
      puts "gender: #{auth.extra.raw_info.gender}"
      user.age_range = auth.extra.raw_info.age_range.min[1]
      puts "age: #{auth.extra.raw_info.age_range.min[1]}"
      if auth.info.email.nil?
        user.email = ""
      else
        user.email = auth.info.email
        puts "email: #{auth.info.email}"
      end
      user.password = Devise.friendly_token[0,20]
      puts "password: #{Devise.friendly_token[0,20]}"
      user.name = auth.info.name
      puts "name: #{auth.info.name}"
      user.picture = auth.info.image.gsub('http://','https://') + "?width=1000&height=1000"
      user.token = auth.credentials.token
      puts "token: #{auth.credentials.token}"
      if auth.credentials.expires_at
        user.token_expiry = Time.at(auth.credentials.expires_at)
      end
    end
  end

  # private

  def send_welcome_email
    UserMailer.welcome(self).deliver
  end

  def send_new_friend_email(friend)
    UserMailer.new_friend(self, friend).deliver
  end

  def send_invite_contact_email_with_restaurant(contact_mail, contact_name, review, resto_id)
    UserMailer.invite_contact(self, contact_mail, contact_name, review, resto_id).deliver
  end

  def send_invite_contact_email_without_restaurant(contact_mail, contact_name)
    UserMailer.invite_contact(self, contact_mail, contact_name).deliver
  end

end
