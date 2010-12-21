class Line < ActiveRecord::Base
  
  acts_as_tree
  
  has_many :mems
  belongs_to :document
  
  # add a mem to each line when created
  before_create :configure_default_mem
  
  def self.preorder_save(lines, parent)
    # Preorder method
    lines.children.each do |line|
      #if line.children
        if line.children.first
          #@lines << {'text' => line.children.first.content}
          newParent = parent.children.create(:text => line.children.first.content, :line_number => line["line_id"])
        end
        if lines.children.length > 1
          self.preorder_save(line, newParent)
        end
      #end
    end
  end

  private

     def configure_default_mem
       self.mems << Mem.create(:strength => 0.5)
     end
  
end
