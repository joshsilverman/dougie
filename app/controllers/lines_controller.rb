class LinesController < ApplicationController
  
  def create
  end
  
  def read
  end
  
  def update

    line = Line.find(params[:line][:id])
    line.update_attributes(params[:line])

    render :json => line

  end
  
  def destroy
  end
  
end
