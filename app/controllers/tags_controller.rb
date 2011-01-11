class TagsController < ApplicationController

  def index

    #create Misc tag if not exists
    
    misc = Tag.find_by_misc(true)
    if misc.nil?
      Tag.create(:misc => true, :name => 'Misc.')
    end

    @tags_json = current_user.tags.includes(:documents)\
                    .all\
                    .to_json(:include => {:documents => {:only => [:id, :name, :updated_at]}})

  end

  def create

    #param check
    name = params[:name]
    if name.nil?
      render :nothing => true, :status => 400
      return
    end

    #create
    current_user.tags << Tag.create(:name => name)

    #return all tag for rerendering dir
    tags_json = current_user.tags.includes(:documents)\
                    .all\
                    .to_json(:include => {:documents => {:only => [:id, :name, :updated_at]}})
    render :json => tags_json

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
    if tag.misc == true or tag.nil?
      render :nothing => true, :status => 400
      return
    end

    #find and destory - related documents are also deleted
    tag.destroy

    #return all tag for rerendering dir

    render :json => current_user.tags.to_json(:include => {:documents => {:only => [:id, :name, :updated_at]}})

  end

  def review

    #check params and tag exists
    
    id = params[:id]
    if id.nil?
      redirect_to '/', :notice => "Unable to locate that directory."
      return
    end

    #get document ids
    @tag = current_user.tags.joins(:documents).find_by_id(id)

    document_ids = []
    @tag.documents.each do |document|
      document_ids.push(document.id)
    end

    #get lines
    @lines_json = Line.includes(:mems)\
                 .where("     lines.document_id IN (?)
                          AND lines.text <> 'root'
                          AND mems.review_after < ?", document_ids, Time.now())\
                 .to_json :include => :mems

    render '/documents/review'

  end

end
