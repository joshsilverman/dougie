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
      @html = sanitize(html)
      @doc = to_nokogiri
      @lines = []
      @rootline = Line.create(:text => "root")
      
 
    
      #collect(@doc,nil)
      #preorder(@doc.children,@rootline)
      
      
    end
    
    def to_nokogiri
      Nokogiri::XML(@html)
    end
    
    def sanitize(html = nil)
      return "" if html.blank?
      html.gsub(/(\\[\w])+/i,"").gsub(/[\s\s]+/," ").gsub(/>\s</,"><").gsub(/<(\/|)ul>|<(\/|)body>|/i,"").gsub(/<p/i,"<li").gsub(/<\/p/,"</li")
    end
    
    def get_nodes(xpath = nil)
       root = "//ul" if xpath.nil?
       @doc.xpath("//ul")
    end
    
    def p_tag(tagName)
      tagName == "p"
    end
    
    def preorder(node_children,parent)
      node_children.each do |root_child|
        parent.children.create(:text => root_child.inner_text)
        p parent.children.create(:text => root_child.inner_text)
        preorder(root_child.children,root_child)
      end
    end
    
    def collect(root,parent) 
      # Preorder method
      root.children.each do |child|
        child.children.each do |grand_child|
          if grand_child.name == "text"
            @lines << grand_child.text
            collect(grand_child,@line)
          end
        end
      end
    end
  end
end