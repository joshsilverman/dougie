class DocumentsController < ApplicationController

  include DocumentsHelper
  
  def index
  end
  
  def create(html = nil)
    
    html = '<body><p changed="1" id="1" line_id="1" active="true">a This is a test - think<br></p> <ul> <li changed="1" id="2" line_id="2" active="true">a the letter \'a\' i am using <ul> <li changed="2" id="3" line_id="3" active="true">a just to keep track [EDIT]</li> <li changed="1" id="4" line_id="4" active="false">a of things that are saved on the first</li> <li changed="1" id="5" line_id="5" active="false">a run through</li> <li changed="2" id="7" line_id="" active="false">b includes two augmentation nodes</li></ul></li><li changed="1" id="6" line_id="6" active="true">a where as items that begin with</li></ul><p changed="2" id="8" line_id="" active="true">b will be included on the second request<br></p></body>'

    html = html ? html : params[:html]
    html = nil if html.blank?
        
    @doc = DOM.new(html)
      
  end
  
end
