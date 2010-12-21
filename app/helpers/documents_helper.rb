include ApplicationHelper
include LinesHelper

module DocumentsHelper
  
  def to_nokogiri(html = nil)
    return nil if html.blank?
    Nokogiri::XML(html)
  end
  
  class DOM
    
    attr_reader :name, :html

    def initialize(document = nil,html = nil)
      return if document.blank? || html.blank?
      @doc = DocumentParser.new(document,html)
    end

  end
  
  class DocumentParser
    
    attr_reader :html, :doc
    
    def initialize(document = nil,html = nil)
      
      return nil if html.blank? || document.nil?
      
      @document = document
      @html = "<li>#{sanitize(html)}</li>"
      @doc = DocumentsHelper::to_nokogiri(@html)
      @lines = [{'text' => ''}]

      root = Line.create(:text => "root")
      Line.preorder_save(@doc.children, root)
      
      @document.lines = root.children
      
    end
    
    def sanitize(html = nil)
      return "" if html.blank?
      html.gsub(/(\\[\w])+/i,"").gsub(/[\s]+/," ").gsub(/>\s</,"><").gsub(/<(\/|)ul>|<(\/|)body>|/i,"").gsub(/<p/i,"<li").gsub(/<\/p/,"</li").gsub(/<br>/,"")
    end

  end
   
end
