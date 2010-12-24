include ApplicationHelper

module DocumentsHelper

  class DocumentParser
    
    attr_reader :html, :doc
    
    def initialize(html = nil)
      
      return nil if html.blank?
      
      @html = "<li>#{sanitize(html)}</li>"
      @doc = to_nokogiri(@html)
      
    end
    
    def sanitize(html = nil)
      return "" if html.blank?
      html.gsub(/(\\[\w])+/i,"").gsub(/[\s]+/," ").gsub(/>\s</,"><").gsub(/<(\/|)ul>|<(\/|)body>|/i,"").gsub(/<p/i,"<li").gsub(/<\/p/,"</li").gsub(/<br>/,"")
    end
    
    def to_nokogiri(html = nil)
      return nil if html.blank?
      Nokogiri::XML(html)
    end

  end
   
end
