class UsersController < ApplicationController

  before_filter :authenticate_user!, :except => [:home, :get_email]

  def home
    redirect_to "/explore" if current_user
  end

  def get_email
  end
  
end
