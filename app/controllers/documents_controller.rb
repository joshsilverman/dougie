class DocumentsController < ApplicationController

  include DocumentsHelper
  
  def index
  end
  
  def new(name = nil)
    
    name = name ? name : params[:name]
    name = "undefined" if name.blank?
    
    @doc = Document.new(name)
      
  end
  
end
