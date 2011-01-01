class MemsController < ApplicationController

  def index
    render :json => Mem.all
  end
  
  def active
    render :json => Mem.where("status = ?",true)
  end
  
  def inactive
    render :json => Mem.where("status = ?",false)
  end
  
  def create
  end
  
  def read
  end
  
  def update

    #params[:id]
    #params[:confidence]
    #params[:importance]

    mem = Mem.find(params[:id])


    render :json => mem
  end
  
  def destroy
  end

end
