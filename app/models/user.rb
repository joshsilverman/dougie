class User < ActiveRecord::Base
  
  validates_length_of :first_name, :minimum => 1
  validates_length_of :last_name, :minimum => 1
  
  has_many :documents 
  has_many :tags
  has_many :mems

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :timeoutable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :first_name, :last_name, :email, :password, :password_confirmation
  
end
