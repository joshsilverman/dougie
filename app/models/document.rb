class Document < ActiveRecord::Base

  has_many :lines
  
  before_save :document_name, :document_html_line_ids
  
  def document_name
    if self.name.blank?
      self.name = "#{Time.now.to_i}"
    end
  end

  def document_html_line_ids

    #html not set
    if self.html.blank? || self.id.blank?
      return true
    end

    #@todo i struggled with nokogiri before submitting to a complex regex
    lines = self.html.scan(/(?:<p|<li)[^>]*(?:[^_]id="([^"]*)"[^>]*line_id="([^"]*)"|line_id="([^"]*)"[^>]*[^_]id="([^"]*)")[^>]*>/)
    lines.each do |line|

      #check for no line id; check that domid exists
      dom_id = line[0] || line[3]
      if (line[1].blank? && line[2].blank? && !dom_id.blank?)

        #retrieve line
        line = Line.where('domid = ? AND document_id = ?', dom_id, self.id).first
        if (!line.blank?)
          id = line.id
          #make substitution - two expressions for readability
          self.html = self.html.gsub(/((?:<p|<li)[^>]*[^_]id="#{dom_id}"[^>]*line_id=")("[^>]*>)/) {"#{$1}#{id}#{$2}"}
          self.html = self.html.gsub(/((?:<p|<li)[^>]*line_id=")("[^>]*[^_]id="#{dom_id}"[^>]*>)/) {"#{$1}#{id}#{$2}"}
        end
      end
    end
  end
  
end
