class UsersController < ApplicationController

  before_filter :authenticate_user!, :except => [:home]

  def home
    redirect_to "/explore" if current_user
  end
  
end
