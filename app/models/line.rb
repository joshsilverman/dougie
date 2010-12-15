class Line < ActiveRecord::Base
  acts_as_tree
  has_many :mems
  belongs_to :document
  
end
