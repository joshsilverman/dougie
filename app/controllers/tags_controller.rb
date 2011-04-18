class TagsController < ApplicationController
  
  helper TagsHelper

  def index

    # create Misc tag if not exists
    misc = current_user.tags.find_by_misc(true)
    if misc.nil?
      Tag.create( :misc => true,
                  :name => 'Misc.',
                  :user_id => current_user.id)
    end
    @tags_json = Tag.tags_json(current_user)

    line_list = Line.includes(:mems)\
      .where("lines.user_id = ? AND mems.status = 1",  current_user.id)\
      .order("mems.updated_at DESC").limit(100)
    recent_docs_ids = []
    line_list.each do |l|
      if recent_docs_ids.size < 3
        unless recent_docs_ids.include?(l.document_id)
          recent_docs_ids << l.document_id
        end
      end
    end
    line_list = line_list.select{|l| recent_docs_ids.include?(l.document_id)}

    @lines_json = line_list.to_json :include => :mems
    @recent_docs = []
    recent_docs_ids.each do |r|
      begin
        @recent_docs << Document.find(r)
      rescue
        # doc not found
      end
    end
  end

  def json
    render :text => Tag.tags_json(current_user)
  end

  def create

    #params
    name = params[:name]

    #create
    Tag.transaction do
      tag = current_user.tags.create(:name => params[:name])

      if tag.nil?
        render :nothing => true, :status => 400
        return
      else
        render :json => Tag.tags_json(current_user)
      end
    end

  end

  def update

    #param check
    if params[:name].nil?
      render :nothing => true, :status => 400
      return
    end

    #create
    Tag.transaction do
      tag = current_user.tags.where('misc IS NULL AND id = ?', params[:id]).first
      if tag.nil?
        render :nothing => true, :status => 403
      else
        tag.update_attribute(:name, params[:name])
        render :json => Tag.tags_json(current_user)
      end
    end

  end

  def destroy

    #param check
    id = params[:id]
    if id.nil?
      render :nothing => true, :status => 400
      return
    end

    #find
    tag = current_user.tags.find_by_id(id)

    #don't delete if Misc, or if nothing's there
    if tag.nil? || tag.misc == true || tag.nil?
      render :nothing => true, :status => 400
      return
    end

    #find and destroy - related documents are also deleted
    tag.destroy

    #return all tag for rerendering dir
    render :json => Tag.tags_json(current_user)

  end

  def review

    #get document ids
    id = params[:id]
    @tag = current_user.tags.joins(:documents).find_by_id(id)

    #check params and tag exists
    if @tag.nil?
      redirect_to '/', :notice => "Error accessing that directory."
      return
    end

    document_ids = []
    @tag.documents.each do |document|
      document_ids.push(document.id)
    end

    #get lines
    @lines_json = Line.includes(:mems)\
                 .where("     lines.document_id IN (?)
                          AND mems.user_id = ?
                          AND mems.status = true
                          AND mems.review_after < ?",
                        document_ids, 
                        current_user.id,
                        Time.now())\
                 .to_json :include => :mems

    render '/documents/review'

  end

end
