class DocumentsController < ApplicationController

  include DocumentsHelper
  
  def index
  end
  
  
  # Look for existing documents (by name for now)
  # If exists, use this document, otherwise set document html and construct Line objects
  def create(name = nil,html = nil)
    
    name = params[:name] || name
    return if name.blank?
    @document = Document.create(name)
    
    render :json => @document

#    #params
#    name = params[:name]
#    html = params[:html]
#    return if name.blank? || html.blank?
#
#    #save
#    document = Document.find_or_create_by_name(name)
#    root = Line.create(:document_id => document.id)
#    parser = DocumentsHelper::DocumentParser.new(html)
#    Line.preorder_save(parser.doc.children, root, document.id)

  end
  
  def read(name = nil)
  end
  
  def update(name = nil, html = nil)

    id = params[:id] || id
    html = params[:html] || html
    @document = Document.find_by_id(id)
    return nil if id.blank? || html.blank? || @document.blank?
    
    if @document.html.blank?
      
      @document.update_attribute(:html,html)
      dp = DocumentParser.new(html)
      root = Line.create(:document_id => @document.id, :text => 'root')
      Line.preorder_save(dp.doc.children, root, @document.id)

    else
    
      @document.update_attribute(:html,html)
      existing_lines = @document.lines
      dp = DocumentParser.new(html)
      root = Line.find_by_document_id(@document.id)
      Line.update_line(dp.doc.children,existing_lines)
      Line.preorder_augment(dp.doc.children, root, existing_lines, @document.id)
      
    end
    
    hsh = Line.id_hash(@document)
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

#    Line.joins(:mems)
#    @lines = Line.where("lines.document_id = ?", params[:id]).to_json :include => :mems
    @lines = Line.where("lines.document_id = ? AND lines.text <> 'root'", params[:id]).to_json
  end
  
end
