class DocumentsController < ApplicationController

  include DocumentsHelper
  
  # Look for existing documents (by name for now)
  # If exists, use this document, otherwise set document html and construct Line objects
  def create

    #get tag if none provided
    tag_id = params[:tag_id]
    if tag_id.nil?
      @tag = Tag.find_by_misc(true) #@todo should query by user_id too

      #generate miscelaneous tag if none
      if @tag.blank?
        @tag = Tag.create(:misc => true, :name => 'Misc')
      end

      tag_id = @tag.id

    else
      #@todo should query by user_id too and what if tag id is invalid...
      @tag = Tag.find_by_id(tag_id)
    end

    @document = Document.create(:name => 'untitled', :tag_id => @tag.id)
    render 'editor'
    
  end
  
  
  def read

    #check id posted
    if params[:id].nil?
      redirect_to '/', :notice => "Error accessing that document."
      return
    end

    #check document exists
    @document = Document.find_by_id(params[:id])
    if @document.nil?
      redirect_to '/', :notice => "Error accessing that document."
      return
    end

    @tag = Tag.find_by_id(@document.tag_id)

    render 'editor'
    
  end
  
  def update

    id = params[:id]
    html = params[:html]
    name = params[:name]
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
   
    Line.preorder_save(dp.doc,@document.id)
    @document.update_attributes(:html => html, :name => name)
    
    hsh = Line.id_hash(Document.find_by_id(id))
    
    render :json => hsh
    
  end
  
  def destroy
    
    if params[:id].nil?
      render :nothing => true, :status => 400
      return
    end
    
    Document.delete(params[:id]) #@todo check user id
    render :json => Tag.all.to_json(:include => {:documents => {:only => [:id, :name, :updated_at]}})
    
  end

  def review

    #check params and document exists
    @document = Document.joins(:tag).find_by_id(params[:id])
    if params[:id].nil? or @document.nil?
      redirect_to '/', :notice => "Unable to locate that document."
      return
    end

    #get lines
    @lines_json = Line.includes(:mems)\
                 .where("     lines.document_id = ?
                          AND lines.text <> 'root'
                          AND mems.review_after < ?", params[:id], Time.now())\
                 .to_json :include => :mems

    #efficient join
    #@todo: why does it need to requery model when building json structure
    #@lines = Line.joins(:mems).where("lines.document_id = ? AND lines.text <> 'root'", params[:id]).to_json :include => :mems
    
  end
  
end
