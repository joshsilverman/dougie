include ApplicationHelper

module DocumentsHelper

  class DocumentParser
    
    attr_reader :html, :lines, :doc
    
    def initialize(html = nil)
      
      return nil if html.blank? 
      @html = sanitize(html)
      @doc = Nokogiri::XML(html)
      
    end
    
    def sanitize(html = nil)
      return "" if html.blank?

      # general adjustments
      html = "<li id=\"node_0\">#{html}</li>"
      html = html.gsub(/(\\[\w])+/i,"").gsub(/[\s]+/," ").gsub(/>\s</,"><").gsub(/<\/?(?:body|ul)[^>]*>/i,"").gsub(/<p/i,"<li").gsub(/<\/p/,"</li").gsub(/<br>/,"").gsub(/<(\/?)LI([^>]*)>/,"<\\1li\\2>")

      # @browser ie adjustments
      html.gsub!(/(<[^>]* line_id)( [^>]*>)/, "\\1=\"\"\\2")
      html.gsub!(/(<[^>]*id=)([^\\"=]*)( [^=]*=[^>]*)?>/, "\\1\"\\2\"\\3>")
      html.gsub!(/(<[^>]*class=)([^\\"=]*)( [^=]*=[^>]*)?>/, "\\1\"\\2\"\\3>")

      puts html
      return html
    end

  end
   
end
