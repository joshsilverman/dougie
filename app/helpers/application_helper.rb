module ApplicationHelper

  def p(obj = "")
    Rails.logger.info obj
  end
  
end
