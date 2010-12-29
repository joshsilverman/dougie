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
  end
  
  def destroy
  end

end
