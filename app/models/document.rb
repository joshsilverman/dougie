class Document < ActiveRecord::Base

  validates_length_of :name, :minimum => 1, :message => "Name cannot be blank."

  has_many :lines

  belongs_to :tag
  belongs_to :user
  
  before_save :document_name
  
  def document_name
    if self.name.blank?
      self.name = "#{Time.now.to_i}"
    end
  end
  
end
