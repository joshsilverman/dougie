class Mem < ActiveRecord::Base
  
  belongs_to :line
  
  def self.create_standard(opts = {})
    
    default_opts = { :status => true, :strength => 0.5 }
    opts.merge!(default_opts)
    
    mem = Mem.new(opts)
    mem.save
    
  end
  
end
