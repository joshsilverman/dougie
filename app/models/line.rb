class Line < ActiveRecord::Base
  
  acts_as_tree
  
  has_many :mems
  belongs_to :document
  
  def self.id_hash(document)
    
    return nil if document.blank?
    
    hsh = {}
    
    document.lines.each do |line|
      
    hsh[line.domid] = line.id unless line.domid.blank?
    
    end
    hsh
    
  end
  
  def self.dom_id(num)
    return "" if num.blank?
    "node_#{num}"
  end
  
  def self.active_cards
    arr = []
    Line.all.each do |line|
      if line.mems.first
        arr << line if line.mems.first.status
      end
    end
    arr
  end
  
  def self.inactive_cards
    arr = []
    Line.all.each do |line|
      if line.mems.first
        arr << line if !line.mems.first.status
      end
    end
    arr
  end
  
  def self.active_mem?(status)
    status.to_s == "true"
  end
  
  def self.preorder_save(lines,document_id)
    
    children = lines.children
    
    children.each do |child|

      parent = child.parent
      
      # check for text node and blank and unsaved lines (blank line_id attributes)
      if child.class == Nokogiri::XML::Text && !parent.attr('parent').blank? && parent.attr("line_id").blank?
        
        # find line in db where domid equals parent's "parent" attribute
        existing_parent = Line.where('domid = ? AND document_id = ?',parent.attr("parent"),document_id).first

        # add line to db, save as variable for mem creation
        created_line = existing_parent.children.create( :text => child.content.strip,
                                                        :domid => parent.attr("id"),
                                                        :document_id => document_id )
                                                        
        # pass in hash of properties to be merged when creating a Mem
        Mem.create_standard({ :line_id => created_line.id,
                              :status => Line.active_mem?(parent.attr("active")) })
                   
      elsif child.children.length > 0
          Line.preorder_save(child,document_id)
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
