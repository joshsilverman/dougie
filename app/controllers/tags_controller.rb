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
                          AND lines.text <> 'root'
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
