include ApplicationHelper

module DocumentsHelper
  
  def sanitize(html = nil)
    return "" if html.blank?
    html.gsub(/(\\[\w])+/i,"").gsub(/[\s]+/," ").gsub(/>\s</,"><").gsub(/<(\/|)ul>|<(\/|)body>|/i,"").gsub(/<p/i,"<li").gsub(/<\/p/,"</li").gsub(/<br>/,"")
  end
  
  class DocumentParser
    
    attr_reader :html, :lines
    
    def initialize(html = nil)
      
      return nil if html.blank?
      
      @html = "<li>#{sanitize(html)}</li>"
      @nokogiri_dom = to_nokogiri
      @lines = [{'text' => ''}]

      root = Line.create(:text => "root")
      preorder_save(@nokogiri_dom.children, root)
      
      @lines = root.children
      
    end
    
    def to_nokogiri
      Nokogiri::XML(@html)
    end

    def preorder_save(lines, parent)
      # Preorder method
      lines.children.each do |line|
        #if line.children
          if line.children.first
            @lines << {'text' => line.children.first.content}
            newParent = parent.children.create(:text => line.children.first.content)
          end
          if lines.children.length > 1
            preorder_save(line, newParent)
          end
        #end
      end
    end
  end
   
end
