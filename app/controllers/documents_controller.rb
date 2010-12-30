class DocumentsController < ApplicationController

  include DocumentsHelper
  
  def index
  end
  
  # Look for existing documents (by name for now)
  # If exists, use this document, otherwise set document html and construct Line objects
  def create
    
    @document = Document.create(:name => 'untitled')
    render 'editor'
    
  end
  
  
  def read(id = nil)

    id = params[:id] || id
    @document = Document.find_by_id(id)

    render 'editor'
    
  end
  
  
  def update(name = nil, html = nil)

    id = params[:id] || id
    html = params[:html] || html
    @document = Document.find_by_id(id)
    return nil if id.blank? || html.blank? || @document.blank?
    
    # create new Nokogiri nodeset
    dp = DocumentParser.new(html)
    
    # pull all existing document line
    existing_lines = @document.lines
    
    root = Line.find_or_create_by_document_id( :document_id => @document.id,
                                               :domid => Line.dom_id(0),
                                               :text => "root" )
    
    Line.update_line(dp.doc,existing_lines) unless @document.html.blank?
      
    @document.update_attribute(:html,html)
    Line.preorder_save(dp.doc, @document.id)
    
    hsh = Line.id_hash(Document.find_by_id(id))
    
    render :json => hsh
    
  end

#  def update
#
#    #params
#    name = params[:name] || name
#    html = params[:html] || html
#    document = Document.find_by_name(name)
#    return nil if name.blank? || html.blank? || document.blank?
#
#    #get existing
#    existing_lines = document.lines
#    root = Line.find_by_document_id(document.id)
#
#    #update and augment
#    document.update_attribute(:html,html)
#    parser = DocumentParser.new(html)
#    Line.update_line(parser.doc.children,existing_lines)
#    Line.preorder_augment(parser.doc.children, root, existing_lines, document.id)
#  end
  
  
  def destroy(name = nil)
    
    name = name ? name : params[:name]
    return nil if name.blank? 
    
    @doc = Document.where("name = ?",name)
    if @doc.length > 0
      @doc.each do |doc|
        doc.destroy
      end
    end
    
  end

  def review()

    #inefficient join via json include
    @lines = Line.where("lines.document_id = ? AND lines.text <> 'root'", params[:id]).to_json :include => :mems

    #efficient join
    #@todo: why does it need to requery model when building json structure
    #@lines = Line.join(:mems).where("lines.document_id = ? AND lines.text <> 'root'", params[:id]).to_json :include => :mems

    #no join
    #@lines = Line.where("lines.document_id = ? AND lines.text <> 'root'", params[:id]).to_json
  end
  
end
