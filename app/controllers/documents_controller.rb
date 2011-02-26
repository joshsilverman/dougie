class DocumentsController < ApplicationController
  
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
    redirect_to :action => 'edit', :id => @document.id
    
  end
  
  def edit

    # check id posted
    id = params[:id]
    if id.nil?
      redirect_to '/', :notice => "Error accessing that document."
      return
    end

    # check document exists
    @document = current_user.documents.find_by_id(id)
    if @document.nil?
      redirect_to '/', :notice => "Error accessing that document."
      return
    end

    @tag = current_user.tags.find_by_id(@document.tag_id)
    @line_ids = Hash[*@document.lines.map {|line| [line.id, line.domid]}.flatten].to_json

    # new document?
    @new_doc = (@document.html.blank?) ? true : false
    
  end
  
  def update

    # update document
    @document = Document.update(params, current_user.id)

    if @document.nil?
        render :nothing => true, :status => 400
        return
    end

    # render {line.domid: line.id} hash
    render :json => Hash[*@document.lines.map {|line| [line.id, line.domid]}.flatten]
    
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

    @document = current_user.documents.find_by_id(params[:id])
    if @document.nil?
      redirect_to '/', :notice => "Error accessing that document."
      return
    end

    # get lines
    @lines_json = Line.includes(:mems)\
                 .where(" lines.document_id = ?
                          AND lines.text <> 'root'
                          AND mems.status = true
                          AND mems.user_id = ?
                          AND mems.review_after < ?",
                        params[:id],
                        current_user.id,
                        Time.now())\
                 .to_json :include => :mems
 
  end
end