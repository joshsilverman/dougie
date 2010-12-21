include ApplicationHelper

module DocumentsHelper
  
  class DOM
    
    attr_reader :html

    def initialize(html = nil)
      @document = Document.create(:name => "chris")
      @doc = DocumentParser.new(@document,html)
    end

  end
  
  class DocumentParser
    
    attr_reader :html, :doc
    
    def initialize(document = nil,html = nil)
      return nil if html.blank? || document.nil?
      @document = document
      @html = "<li>%s</li>" % sanitize(html)
      @doc = Nokogiri::XML(@html)
      @lines = [{'text' => ''}]

      root = Line.create(:text => "root")
      preorder_save(@doc.children, root)
      
      @document.lines = root.children
      
    end
    
    def sanitize(html = nil)
      return "" if html.blank?
      html.gsub(/(\\[\w])+/i,"").gsub(/[\s]+/," ").gsub(/>\s</,"><").gsub(/<(\/|)ul>|<(\/|)body>|/i,"").gsub(/<p/i,"<li").gsub(/<\/p/,"</li").gsub(/<br>/,"")
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
