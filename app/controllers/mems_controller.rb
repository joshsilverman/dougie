class MemsController < ApplicationController

  def index
    render :json => Mem.all
  end

  #@todo depracate
  def active
    render :json => Mem.active_mems
  end

  #@todo depracate
  def inactive
    render :json => Mem.inactive_mems
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
