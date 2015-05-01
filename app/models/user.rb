class User < ActiveRecord::Base

  has_many :recommendations, dependent: :destroy
  has_many :friendships
  has_many :senders, :through => :friendships
  has_many :receivers, :through => :friendships


  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :omniauth_providers => [ :facebook ]

  has_attached_file :picture,
      styles: { large: "800x800", medium: "300x300>", thumb: "50x50#" }
    validates_attachment_content_type :picture,
      content_type: /\Aimage\/.*\z/


  def friendships_by_status()
    user_friends = []
    user_requests = []
    user_propositions = []
    my_friendships = Friendship.includes([:sender, :receiver]).where("sender_id = ? or receiver_id = ?",  self.id, self.id)
    my_friendships.each do |friendship|
      if friendship.accepted
        if friendship.receiver_id == self.id
          user_friends << { friendship_user: friendship.sender, friendship_relation: friendship }
        else
          user_friends << { friendship_user: friendship.receiver, friendship_relation: friendship }
        end
      else
        if friendship.receiver_id == self.id
          user_propositions << { friendship_user: friendship.sender, friendship_relation: friendship }
        else
          user_requests << { friendship_user: friendship.receiver, friendship_relation: friendship }
        end
      end
    end
    {user_friends: user_friends, user_propositions: user_propositions, user_requests: user_requests}
  end

  def self.find_for_facebook_oauth(auth)
      where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
        user.provider = auth.provider
        user.uid = auth.uid
        user.email = auth.info.email
        user.password = Devise.friendly_token[0,20]  # Fake password for validation
        user.name = auth.info.name
        user.picture = auth.info.image.gsub('http://','https://') + "?width=1000&height=1000"
        user.token = auth.credentials.token
        user.token_expiry = Time.at(auth.credentials.expires_at)
      end
    end
end
