class LinesController < ApplicationController
  
  def index
    render :json => Line.all
  end
  
  def active
    render :json => Line.active_cards
  end
  
  def inactive
    render :json => Line.inactive_cards
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
