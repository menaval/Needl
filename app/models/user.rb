class User < ActiveRecord::Base
  has_many :recommendations
  has_many :friendships
  has_many :senders, :through => :friendships
  has_many :receivers, :through => :friendships

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :omniauth_providers => [ :facebook ]

  has_attached_file :picture,
      styles: { medium: "300x300>", thumb: "50x50#" }
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
          user_friends << friendship.sender
        else
          user_friends << friendship.receiver
        end
      else
        if friendship.receiver_id == self.id
          user_propositions << friendship.sender
        else
          user_requests << friendship.receiver
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
        user.picture = auth.info.image
        user.token = auth.credentials.token
        user.token_expiry = Time.at(auth.credentials.expires_at)
      end
    end
end
