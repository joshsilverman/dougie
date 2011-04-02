class ApplicationController < ActionController::Base

  before_filter :check_uri
  before_filter :authenticate_user!
  
  helper :all
  
  protect_from_forgery
  include ApplicationHelper

  def check_uri
    logger.info "redirect to: #{request.protocol + request.host_with_port + request.request_uri}\n"
    logger.info "reques protocol: #{request.protocol}\n"
    logger.info "reques host_with_port #{request.host_with_port}\n"
    logger.info "reques request_uri #{request.request_uri}\n"
    logger.info "reques host #{request.host}\n"
    redirect_to request.protocol + request.host_with_port + request.request_uri if /^www/.match(request.host)
  end

end
