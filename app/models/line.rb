class Line < ActiveRecord::Base
  
  acts_as_tree
  
  has_many :mems, :dependent => :destroy
  belongs_to :document

  cattr_accessor :document_html

  def self.active_mem?(status)
    status.to_s == "true"
  end
  
  def self.preorder_save(lines,document_id,saved_parents,user_id)
    
    lines.children.each do |child|

      parent = child.parent

      # check for text node and blank and unsaved lines (blank line_id attributes)
      if child.class == Nokogiri::XML::Text && !parent.attr('parent').blank? && parent.attr("line_id").blank?

        # find line in db where domid equals parent's "parent" attribute
        parent_attr = parent.attr("parent") || nil
        if saved_parents[parent_attr]
            existing_parent = saved_parents[parent_attr]
        else
          existing_parent = Line.where({ :domid => parent_attr, :document_id => document_id }).first
          saved_parents[parent_attr] = existing_parent
        end

        # add line to db, save as variable for mem creation
        dom_id = parent.attr("id")
        created_line = existing_parent.children.create( :text => child.content.strip,
                                                        :user_id => user_id,
                                                        :domid => dom_id,
                                                        :document_id => document_id )

        @@document_html.gsub!(/((?:<p|<li)[^>]*[^_]id="#{dom_id}"[^>]*line_id=")("[^>]*>)/) {"#{$1}#{created_line.id}#{$2}"}
        @@document_html.gsub!(/((?:<p|<li)[^>]*line_id=")("[^>]*[^_]id="#{dom_id}"[^>]*>)/) {"#{$1}#{created_line.id}#{$2}"}

        # pass in hash of properties to be merged when creating a Mem
        mem = Mem.create({:strength => 0.5,
                          :user_id => user_id,
                          :line_id => created_line.id,
                          :status => parent.attr("active") == 'true',
                          :review_after => Time.now})

      elsif child.children.length > 0
          Line.preorder_save(child,document_id,saved_parents,user_id)
      end
    end
    
  end
  
  def self.update_line(lines,existing_lines,user_id)

    existing_lines_hash = {}
    existing_lines.each do |e_line|
      existing_lines_hash[e_line.id] = e_line
    end

    # find all lines with line_id attribute
    lines.css("li").each do |line|

      unless object_id.blank?

        if existing_lines_hash[line.attr('line_id').to_i].blank?
          next
        else
          e_line = existing_lines_hash[line.attr('line_id').to_i]
        end

        # existing line epoch updated_at less than incoming line epoch change time
        if line.attr('changed') == "1"

          # replace existing line text with incoming line text
          text = line.to_s.scan(/>([^<]*)/)[0][0].strip
          e_line.update_attribute(:text,text)

          # update mem status
          # @todo - combine into one query
          status = (line.attr('active') == nil) ? 0 : 1
          Mem.find(:first, :conditions => {:line_id => e_line.id, :user_id => user_id})\
                .update_attribute(:status, status)
        end
      end
    end
  end
  
end
