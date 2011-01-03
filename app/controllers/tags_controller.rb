class TagsController < ApplicationController

  def index

    @tags_json = Tag.all.to_json(:include => {:documents => {:only => [:id, :name, :updated_at]}})

  end

end
