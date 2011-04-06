class ApplicationController < ActionController::Base

  before_filter :check_uri
  before_filter :prepare_for_mobile
  before_filter :authenticate_user!
  
  helper :all
  
  protect_from_forgery
  include ApplicationHelper

  def check_uri
#    logger.info "redirect to: #{request.protocol + request.host_with_port + request.request_uri}\n"
#    logger.info "reques protocol: #{request.protocol}\n"
#    logger.info "reques host_with_port #{request.host_with_port}\n"
#    logger.info "reques request_uri #{request.request_uri}\n"
#    logger.info "reques host #{request.host}\n"

    if /^www\./.match(request.host_with_port)
      host = request.host_with_port.gsub(/^www\./, "")
      redirect_loc = request.protocol + host + request.request_uri
      redirect_logger.info("\n#{Time.now.to_s(:db)}\nredirect to: #{redirect_loc}\n")

      redirect_to redirect_loc
    end
  end

  def redirect_logger
    @@redirect_logger ||= Logger.new("#{RAILS_ROOT}/log/redirect.log")
  end

  private
  def mobile_device?
    request.user_agent =~ /Mobile|webOS/
  end
  helper_method :mobile_device?

  def prepare_for_mobile
    request.format = :mobile #if mobile_device?
  end
end
