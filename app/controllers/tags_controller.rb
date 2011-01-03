class TagsController < ApplicationController

  def index

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

    #find and destory - related documents are also deleted
    tag = Tag.find(params[:id])
    tag.destroy()

    #return all tag for rerendering dir
    render :json => Tag.all.to_json(:include => {:documents => {:only => [:id, :name, :updated_at]}})

  end

end
