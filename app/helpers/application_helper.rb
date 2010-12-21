module ApplicationHelper

  def p(obj = "")

    puts 'test'

    Rails.logger.info ''
    Rails.logger.info obj#.to_yaml
    Rails.logger.info ''
  end
  
end
