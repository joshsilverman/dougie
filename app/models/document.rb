class Document < ActiveRecord::Base

  has_many :lines
  
  before_save :document_name
  
  def document_name
    if self.name.blank?
      self.name = "#{Time.now.to_i}"
    end
  end
  
  
end
