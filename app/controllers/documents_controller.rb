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

    id = params[:id]
    html = params[:html]
    delete_nodes = params[:delete_nodes]
    @document = current_user.documents.find_by_id(id)
#    @document = Document.includes(:lines).where(:id => id, :user_id => current_user.id).first //@todo combind existing lines query with this one
    return nil if id.blank? || html.blank? || @document.blank?
    
    # pull all existing document line
    existing_lines = @document.lines

    # group transaction; track whether lines deleted
    deleted_lines = false
    Line.transaction do
      # look for root in existing lines
      root = nil
      existing_lines.each do |line|
        if line.domid == "node_0"
          root = line
          break
        end
      end

      # create root
      if root.nil?
        root = Line.create(:document_id => @document.id,:domid => "node_0",:text => "root" )
      end

      # run update line; store whether anything was changed
      dp = DocumentParser.new(html)
      Line.update_line(dp.doc,existing_lines) unless @document.html.blank?

      Line.document_html = html
      Line.new_line = false
      Line.preorder_save(dp.doc,@document.id, {'node_0' => root})

      @document.update_attributes(:html => Line.document_html, :name => params[:name])

      # delete lines/mems (don't use destory_all with dependencies) - half as many queries; track whether deleted
      deleted_lines = false
      unless delete_nodes == '[]' || delete_nodes.nil? || delete_nodes == ''
        deleted_lines = true
        Line.delete_all(["id IN (?) AND document_id = ?", delete_nodes.split(','), @document.id])
        Mem.delete_all(["line_id IN (?)", delete_nodes.split(',')]) # belongs in model but I think before_delete would delete mems infividually
      end
    end

    # refresh existing lines and create hash
    if Line.new_line || deleted_lines
      lines = Line.find_all_by_document_id(id)
    else
      lines = existing_lines
    end

    # render {line.domid: line.id} hash
    render :json => Hash[*lines.map {|line| [line.domid, line.id]}.flatten]
    
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
    
    render :json => Tag.tags_json(current_user)
    
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
                 .where(" lines.document_id = ?
                          AND lines.text <> 'root'
                          AND mems.review_after < ?", params[:id], Time.now())\
                 .to_json :include => :mems
 
  end
end