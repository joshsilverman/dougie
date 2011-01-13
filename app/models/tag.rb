class Tag < ActiveRecord::Base

  has_many :documents, :dependent => :destroy
  belongs_to :user
  
  def self.tags_json(current_user = nil)
    return nil if current_user.blank?
    current_user.tags.includes(:documents)\
                    .all\
                    .to_json(:include => {:documents => {:only => [:id, :name, :updated_at]}})
    rescue: []
  end

end
