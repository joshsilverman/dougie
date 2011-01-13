class Line < ActiveRecord::Base
  
  acts_as_tree
  
  has_many :mems
  belongs_to :document

  cattr_accessor :document_html

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

  #@deprecate
  def self.active_cards
    arr = []
    Line.all.each do |line|
      if line.mems.first
        arr << line if line.mems.first.status
      end
    end
    arr
  end

  #@deprecate
  def self.inactive_cards
    arr = []
    Line.all.each do |line|
      if line.mems.first
        arr << line if !line.mems.first.status
      end
    end
    arr
  end

  #@deprecate?
  def self.active_mem?(status)
    status.to_s == "true"
  end
  
  def self.preorder_save(lines,document_id,saved_parents = {})
    
    lines.children.each do |child|

      parent = child.parent
      parent_attr = parent.attr('parent')
      
      # check for text node and blank and unsaved lines (blank line_id attributes)
      if child.class == Nokogiri::XML::Text && !parent_attr.blank? && parent.attr("line_id").blank?
        
        # find line in db where domid equals parent's "parent" attribute
        
        saved_parent = saved_parents[parent_attr]
        unless saved_parent.blank?
          existing_parent = saved_parent
        else 
          existing_parent = Line.where({ :domid => parent_attr, :document_id => document_id }).first
          saved_parents[parent_attr] = existing_parent
        end

        # add line to db, save as variable for mem creation
        dom_id = parent.attr("id")
        created_line = existing_parent.children.create( :text => child.content.strip,
                                                        :domid => dom_id,
                                                        :document_id => document_id )

        @@document_html.gsub!(/((?:<p|<li)[^>]*[^_]id="#{dom_id}"[^>]*line_id=")("[^>]*>)/) {"#{$1}#{created_line.id}#{$2}"}
        @@document_html.gsub!(/((?:<p|<li)[^>]*line_id=")("[^>]*[^_]id="#{dom_id}"[^>]*>)/) {"#{$1}#{created_line.id}#{$2}"}

        # pass in hash of properties to be merged when creating a Mem
        Mem.create_standard({ :line_id => created_line.id,
                              :status => Line.active_mem?(parent.attr("active")),
                              :review_after => Time.now})
                   
      elsif child.children.length > 0
          Line.preorder_save(child,document_id,saved_parents)
      end
    end
    
  end
  
  def self.update_line(lines,existing_lines)

    existing_lines_hash = {}
    existing_lines.each do |e_line|
      existing_lines_hash[e_line.id] = e_line
    end

    # find all lines with line_id attribute
    lines.css("li").each do |line|

      unless object_id.blank?

        line_id = line.attr('line_id').to_i
        
        unless existing_lines_hash[line_id].blank?
          e_line = existing_lines_hash[line_id]

          # replace existing line text with incoming line text
          # updated_at time is automatically set by rails
          text = line.to_s.scan(/>([^<]*)/)[0][0].strip
          e_line.update_attribute(:text,text)

        end
      end
    end
  end
  
end
