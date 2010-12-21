class Line < ActiveRecord::Base
  
  acts_as_tree
  
  has_many :mems
  belongs_to :document
  
  # add a mem to each line when created
  before_create :configure_default_mem

   private

     def configure_default_mem
       self.mems << Mem.create(:strength => 0.5)
     end
  
end
