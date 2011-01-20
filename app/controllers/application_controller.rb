class ApplicationController < ActionController::Base
  
  before_filter :authenticate_user!
  
  helper :all
  
  protect_from_forgery
  include ApplicationHelper
      
end
