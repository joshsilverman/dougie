class Line < ActiveRecord::Base
  
  acts_as_tree
  
  has_many :mems
  belongs_to :document
  
  # add a mem to each line when created
  before_create :configure_default_mem
  
  def self.preorder_save(lines, parent)
    # Preorder method
    lines.children.each do |line|
      if line.children.first
        newParent = parent.children.create(:text => line.children.first.content, :line_number => line["line_id"])
      end
      if lines.children.length > 1
        self.preorder_save(line, newParent)
      end
    end
  end
  
  def self.preorder_update(lines,existing_lines)
    # Preorder method
    
    lines.css("li[line_id]").each do |line|
      unless id.blank?
        existing_lines.each do |e_line|
          
          #existing line_number equals incoming line number
          if e_line.line_number.to_s == line.attr('line_id').to_s
            
            #existing line epoch updated_at less than incoming line epoch change time
            if e_line.updated_at.to_i < line.attr('changed').to_i
              
              # debug
              # p "LINE CHANGED!"
              # p "ELINE: #{e_line.updated_at.to_i}"
              # p "LINE: #{line}"
              # p "TEXT: #{line.text}"
              
              # replace existing line text with incoming line text
              # updated_at time is automatically set by rails
              e_line.update_attribute(:text,line.text)
              
            end
          end
        end
      end
    end
  end

  private

     def configure_default_mem
       self.mems << Mem.create(:strength => 0.5)
     end
  
end
