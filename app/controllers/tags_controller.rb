class TagsController < ApplicationController

  def index

    #create Misc tag if not exists
    misc = Tag.find_by_misc(true)
    if misc.nil?
      Tag.create(:misc => true, :name => 'Misc.')
    end

    @tags_json = Tag.all.to_json(:include => {:documents => {:only => [:id, :name, :updated_at]}})

  end

  def create

    #param check
    if params[:name].nil?
      render :nothing => true, :status => 400
      return
    end

    #create
    Tag.create(:name => params[:name])

    #return all tag for rerendering dir
    render :json => Tag.all.to_json(:include => {:documents => {:only => [:id, :name, :updated_at]}})

  end

  def destroy

    #param check
    if params[:id].nil?
      render :nothing => true, :status => 400
      return
    end

    #find
    tag = Tag.find(params[:id])

    #don't delete if Misc, or if nothing's there
    if tag.misc == true or tag.nil?
      render :nothing => true, :status => 400
      return
    end

    #find and destory - related documents are also deleted
    tag.destroy()

    #return all tag for rerendering dir
    render :json => Tag.all.to_json(:include => {:documents => {:only => [:id, :name, :updated_at]}})

  end

  def review

    #check params and tag exists
    if params[:id].nil? or Tag.find_by_id(params[:id]).blank?
      redirect_to '/', :notice => "Unable to locate that directory."
      return
    end

    #get document ids
    @tag = Tag.joins(:documents).find(params[:id])

    document_ids = []
    @tag.documents.each do |document|
      document_ids.push(document.id)
    end

    #inefficient join via json include
    @lines = Line.joins(:mems)\
                 .where("     lines.document_id IN (?)
                          AND lines.text <> 'root'
                          AND mems.review_after < ?", document_ids, Time.now())\
                 .to_json :include => :mems

    render '/documents/review'

  end

end
