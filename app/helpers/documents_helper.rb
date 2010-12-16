module DocumentsHelper
  
  class Document
    
    attr_accessor :name

    def initialize(name = nil)
      @name = name
    end  

  end
   
end
