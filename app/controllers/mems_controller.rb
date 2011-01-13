class MemsController < ApplicationController
  
  def update

    mem = Mem.find(params[:id])
    mem.update_reviewed(params[:confidence], params[:importance])

    render :nothing => true
  end

end
