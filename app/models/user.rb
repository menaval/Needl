class User < ActiveRecord::Base

  acts_as_token_authenticatable
  has_many :recommendations, dependent: :destroy
  has_many :wishes, dependent: :destroy

  has_many :friendships, foreign_key: :sender_id, dependent: :destroy
  has_many :received_friendships, foreign_key: :receiver_id, class_name: 'Friendship', dependent: :destroy

  has_many :followerships, foreign_key: :following_id, dependent: :destroy
  has_many :received_followerships, foreign_key: :follower_id, class_name: 'Followership', dependent: :destroy

  has_many :not_interested_relations, foreign_key: :refused_id, dependent: :destroy
  has_many :received_not_interested_relations, foreign_key: :refuser_id, class_name: 'NotInterestedRelation', dependent: :destroy

  has_many :taste_correspondences, foreign_key: :member_two_id, dependent: :destroy
  has_many :mutual_taste_correspondences, foreign_key: :member_one_id, class_name: 'TasteCorrespondence', dependent: :destroy

  has_many :senders, :through => :received_friendships, dependent: :destroy
  has_many :receivers, :through => :friendships, dependent: :destroy

  has_many :followings, :through => :received_followerships, dependent: :destroy
  has_many :followers, :through => :followerships, dependent: :destroy

  has_many :refusers, :through => :not_interested_relations, dependent: :destroy
  has_many :refuseds, :through => :received_not_interested_relations, dependent: :destroy

  has_many :member_ones, :through => :taste_correspondences, dependent: :destroy
  has_many :member_twos, :through => :mutual_taste_correspondences, dependent: :destroy

  has_many :imported_contacts, dependent: :destroy

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
    user_ids = self.refusers.pluck(:id)
    user_ids += self.refuseds.pluck(:id)
  end

  def my_visible_friends_restaurants_ids
    user_ids = my_visible_friends_ids
    restos_ids = Restaurant.joins(:recommendations).where(recommendations: { user_id: user_ids }).pluck(:id)
    restos_ids += Restaurant.joins(:wishes).where(wishes: {user_id: user_ids}).pluck(:id)
  end

  def my_friends_restaurants_ids
    user_ids = my_friends_ids
    restos_ids = Restaurant.joins(:recommendations).where(recommendations: { user_id: user_ids }).pluck(:id)
    restos_ids += Restaurant.joins(:wishes).where(wishes: {user_id: user_ids}).pluck(:id)
  end

  def my_experts_restaurants_ids
    experts_ids = self.followings.pluck(:id)
    restos_ids = Restaurant.joins(:recommendations).where(recommendations: {user_id: experts_ids, public: true}).pluck(:id)
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

  def my_public_recos
    Restaurant.joins(:recommendations).where(recommendations: { user_id: self.id, public: true })
  end

  def my_wishes
    Restaurant.joins(:wishes).where(wishes: {user_id: self.id})
  end

  def my_friends_foods
    Food.joins(restaurants: :recommendations).where(recommendations: {user_id: my_visible_friends_ids}).uniq
  end

  # ne sert plus a rien sur l'app mais bug (avec contacts_thanking en json)
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
      user.provider = auth.provider
      user.uid = auth.uid
      user.gender = auth.extra.raw_info.gender
      # a remettre quand on aura été validé
      # user.birthday = Date.parse(auth.extra.raw_info.birthday)
      if auth.info.email.nil?
        # pour créer des adresses mails à ceux qui n'en ont pas renseigné sur facebook
        adresses = User.all.pluck(:email)
        i = 1
        while i > 0
          if adresses.include?("blank#{i}@needlapp.com") == false
            user.email = "blank#{i}@needlapp.com"
            user.emails << "blank#{i}@needlapp.com"
            break
          end
          i += 1
        end
      else
        user.email = auth.info.email
        user.emails << auth.info.email
      end
      user.password = Devise.friendly_token[0,20]
      user.name = auth.info.name
      user.picture = auth.info.image.gsub('http://','https://') + "?width=1000&height=1000"
      user.token = auth.credentials.token
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

  def send_invite_contact_with_restaurant_email(contact_mail, contact_name, review, resto_id)
    UserMailer.invite_contact_with_restaurant(self, contact_mail, contact_name, review, resto_id).deliver
  end

  def send_invite_contact_without_restaurant_email(contact_mail, contact_name)
    UserMailer.invite_contact_without_restaurant(self, contact_mail, contact_name).deliver
  end

  def send_thank_friends_email(friends_infos, restaurant_id)
    UserMailer.thank_friends(self, friends_infos, restaurant_id).deliver
  end

  # def send_thank_contacts_email(contacts_infos, restaurant_id)
  #   UserMailer.thank_contacts(self, contacts_infos, restaurant_id).deliver
  # end

end
