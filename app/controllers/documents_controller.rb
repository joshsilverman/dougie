class DocumentsController < ApplicationController

  include DocumentsHelper
  
  def index
  end
  
  
  # Look for existing documents (by name for now)
  # If exists, use this document, otherwise set document html and construct Line objects
  def create(name = nil,html = nil)

    #params
    name = params[:name]
    html = params[:html]
    return if name.blank? || html.blank?

    #save
    document = Document.find_or_create_by_name(name)
    root = Line.create(:document_id => document.id)
    parser = DocumentsHelper::DocumentParser.new(html)
    Line.preorder_save(parser.doc.children, root, document.id)
  end
  
  def read(name = nil)
  end
  
  
  def update

    #params
    name = params[:name] || name
    html = params[:html] || html
    document = Document.find_by_name(name)
    return nil if name.blank? || html.blank? || document.blank?

    #get existing
    existing_lines = document.lines
    root = Line.find_by_document_id(document.id)

    #update and augment
    document.update_attribute(:html,html)
    parser = DocumentParser.new(html)
    Line.update_line(parser.doc.children,existing_lines)
    Line.preorder_augment(parser.doc.children, root, existing_lines, document.id)
  end
  
  
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
  
end
