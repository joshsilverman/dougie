class User < ActiveRecord::Base
  
#  validates_length_of :first_name, :minimum => 1
#  validates_length_of :last_name, :minimum => 1

  has_many :authentications, :dependent => :destroy
  has_many :documents 
  has_many :tags
  has_many :mems
  has_many :reps

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :timeoutable
  devise :database_authenticatable, :registerable, 
         :recoverable, :rememberable, :trackable, :validatable, 
         :token_authenticatable, :confirmable, :lockable, :timeoutable
  
  # Setup accessible (or protected) attributes for your model
  attr_accessible :first_name, :last_name, :email, :password, :password_confirmation

  def apply_omniauth(omniauth)

    if (!omniauth['user_info']['email'].nil?)
      self.email = omniauth['user_info']['email']
    elsif omniauth['extra'] && email.blank?
        self.email = omniauth['extra']['user_hash']['email']
    end
    
    self.first_name = omniauth['user_info']['first_name'] if first_name.blank?
    self.last_name = omniauth['user_info']['last_name'] if last_name.blank?

    # seed password with random string
    self.password = ActiveSupport::SecureRandom.hex(16)[0,20]

    authentications.build(:provider => omniauth['provider'], :uid => omniauth['uid'])
  end

  def password_required?
    (authentications.empty? || !password.blank?) && super
  end

end
