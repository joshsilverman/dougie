class ApplicationController < ActionController::Base

  before_filter :check_uri
  before_filter :authenticate_user!
  
  helper :all
  
  protect_from_forgery
  include ApplicationHelper

  def check_uri
    redirect_to request.protocol + request.host_with_port + request.request_uri if /^www/.match(request.host)
  end

end
