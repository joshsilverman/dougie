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

    mem = Mem.find(params[:id])
    mem.update_reviewed(params[:confidence], params[:importance])

    render :nothing => true
  end
  
  def destroy
  end

end
