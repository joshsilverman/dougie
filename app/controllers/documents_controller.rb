class DocumentsController < ApplicationController

  include DocumentsHelper
  
  def index
  end
  
  
  # Look for existing documents (by name for now)
  # If exists, use this document, otherwise set document html and construct Line objects
  def create(name = nil,html = nil)
    
    # TEST DATA
    name = 'chris'
    html = '<body><p changed="1" id="1" line_id="1" active="true">a This is a test - think<br></p><ul><li changed="1" id="2" line_id="2" active="true">a the letter \'a\' i am using <ul> <li changed="2" id="3" line_id="3" active="true">a just to keep track [EDIT]</li> <li changed="1" id="4" line_id="4" active="false">a of things that are saved on the first</li> <li changed="1" id="5" line_id="5" active="false" delete=\'true\' style="display:none">a run through</li> <li changed="2" id="7" line_id="7" active="false">b includes two augmentation nodes</li> <li changed="3" id="9" line_id="" active="true">c a little more augmentation</li> </ul> </li><li changed="1" id="6" line_id="6" active="true">a where as items that begin with</li></ul> <p changed="2" id="8" line_id="8" active="true">b will be included on the second request<br></p><ul><li changed="3" id="10" line_id="" active="false">c augmentation! <ul> <li changed="3" id="11" line_id="" active="false">c yeah</li> <li changed="3" id="12" line_id="" active="true">c augment me</li> <li changed="3" id="13" line_id="" active="false">c yea heck yeah augmentation</li> </ul> </li></ul></body>'
    
    name = params[:name] || name
    html = params[:html] || html
    
    return if name.blank? || html.blank?
    
    @document = Document.find_or_create_by_name(name)
    
    if @document.html.blank?
      @document.update_attribute(:html,html)
      @dom = DOM.new(@document,html)
    end
    
    @document
      
  end
  
  
  def read(name = nil)
    
    name = params[:name] || name
    @doc = Document.where("name = ?",name)
    
  end
  
  
  def update
  end
  
  
  def delete(name = nil)
    
    name = name ? name : params[:name]
    return nil if name.blank? 
    
    @doc = Document.where("name = ?",name)
    if @doc.length > 0
      @doc.each do |doc|
        doc.destroy
      end
    end
    
  end
  
end
