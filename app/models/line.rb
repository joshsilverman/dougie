class Line < ActiveRecord::Base
  
  acts_as_tree
  
  has_many :mems
  belongs_to :document
  
  def self.id_hash(document)
    
    return nil if document.blank?
    
    hsh = {}
    document.lines.each do |line|
      
      unless line.domid.blank?
        hsh[line.domid] = line.id
      end
    
    end
    hsh
    
  end
  
  def self.preorder_save(lines, parent, document_id)
    
    lines.children.each do |line|
      
      # save child as line
      if line.children.first
        
        created_line = parent.children.create(:text => line.children.first.content, 
                                              :domid => line.attr("id"),
                                              :document_id => document_id )
        
        Mem.create_standard({ :line_id => created_line.id })
      end
      
      # traverse through liens with more than one parent  
      if line.children.length > 1
        self.preorder_save(line, created_line, document_id)
      end
      
    end
  end
  
  def self.preorder_augment(lines, parent, existing_lines, document_id)
    
    lines.children.each do |line|
      
      # save child as line only if unregistered
      if line.children.first && line.attr("line_id").blank?
        
        created_line = parent.children.create(:text => line.children.first.content, 
                                              :domid => line.attr("id"),
                                              :document_id => document_id )
        
        Mem.create_standard({ :line_id => created_line.id })
        
      end
      
      # traverse through lines with more than one parent  
      if line.children.length > 1
        self.preorder_save(line, created_line, document_id)
      end
      
    end
    
  end
  
  def self.update_line(lines,existing_lines)
    
    # find all lines with line_id attribute
    lines.css("li[line_id]").each do |line|
      
      unless id.blank?
        existing_lines.each do |e_line|
          
          #existing line_number equals incoming line number
          if e_line.id.to_s == line.attr('line_id').to_s
            
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
  
end
