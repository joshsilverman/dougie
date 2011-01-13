class DocumentsController < ApplicationController

  include DocumentsHelper
  
  # Look for existing documents (by name for now)
  # If exists, use this document, otherwise set document html and construct Line objects
  def create

    #attempt to use a provided tag
    tag_id = params[:tag_id]
    if tag_id
      @tag = current_user.tags.find_by_id(tag_id)
    end

    # if not tag look for misc or create misc
    if @tag.blank?
      @tag = current_user.tags.find_by_misc(true) #@todo should query by user_id too

      #generate miscelaneous tag if none
      if @tag.blank?
        @tag = current_user.tags.create(:misc => true, :name => 'Misc')
      end
    end

    @document = current_user.documents.create(:name => 'untitled', :tag_id => @tag.id)
    redirect_to :action => 'read', :id => @document.id
    
  end
  
  def read

    #check id posted
    id = params[:id]
    if id.nil?
      redirect_to '/', :notice => "Error accessing that document."
      return
    end

    #check document exists
    @document = current_user.documents.find_by_id(id)
    if @document.nil?
      redirect_to '/', :notice => "Error accessing that document."
      return
    end

    @tag = current_user.tags.find_by_id(@document.tag_id)
    
  end
  
  def update

    f = open('tmp/benchmarks/doc-update.txt', 'a');
    f.puts("\n\n*** documents/update ***\n\n")
    start_time = Time.now

    id = params[:id]
    html = params[:html]
    @document = current_user.documents.find_by_id(id)
    return nil if id.blank? || html.blank? || @document.blank?

    name = params[:name]
    
    # create new Nokogiri nodeset
    dp = DocumentParser.new(html)
    
    # pull all existing document line
    existing_lines = @document.lines

    Line.transaction do
      root = Line.find_or_create_by_document_id( :document_id => @document.id,
                                                 :domid => Line.dom_id(0),
                                                 :text => "root" )

      f.puts('Doc created:' + (Time.now - start_time).to_s + "\n")

      Line.update_line(dp.doc,existing_lines) unless @document.html.blank?

      f.puts('Lines updated:' + (Time.now - start_time).to_s + "\n")

      Line.document_html = html
      Line.preorder_save(dp.doc,@document.id)

      f.puts('Preorder save:' + (Time.now - start_time).to_s + "\n")

      @document.update_attributes(:html => Line.document_html, :name => name)

    end

    f.puts('Doc updated:' + (Time.now - start_time).to_s + "\n")

    hsh = Line.id_hash(@document)
    
    render :json => hsh

    f.puts('Controller time:' + (Time.now - start_time).to_s + "\n")
    
  end
  
  def destroy
    id = params[:id]
    if id.nil?
      render :nothing => true, :status => 400
      return
    end
    
    #Document.delete({ :id => params[:id], :user_id => current_user.id }) #@todo check user id
    
    document = current_user.documents.find_by_id(id)
    document.delete unless document.blank?
    
    render :json => current_user.tags.to_json(:include => {:documents => {:only => [:id, :name, :updated_at]}})
    
  end

  def review

    #check params and document exists
    id = params[:id]
    if id.nil?
      render :nothing => true, :status => 400
      return
    end

    @document = current_user.documents.find_by_id(id)

    #get lines
    @lines_json = Line.includes(:mems)\
                 .where("     lines.document_id = ?
                          AND lines.text <> 'root'
                          AND mems.review_after < ?", params[:id], Time.now())\
                 .to_json :include => :mems
 
  end
end