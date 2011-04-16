class Line < ActiveRecord::Base
  
  has_many :mems, :dependent => :destroy
  belongs_to :document

  cattr_accessor :document_html

  def self.active_mem?(status)
    status.to_s == "true"
  end
  
  def self.save_all(doc,document_id,user_id)
    doc.css("li").each do |line|
      puts "\n\nyo\n\n"
      next if line.attr('style') =~ /(.*)changed(.*)/
      dom_id = line.attr("id")
      puts "\n\ngo\n\n"
      existing_line = Line.where(:user_id => user_id,
                            :domid => dom_id,
                            :document_id => document_id ).first
      if line.attr("active") == 'true'
        if (not existing_line.nil?)
          existing_mem = Mem.where(:user_id => user_id,
                                   :line_id => existing_line.id).first

          # legacy support for mems that can have status set to 0
          if (existing_mem)
            existing_mem.update_attribute(:status, 1) unless (existing_mem.status == 1)
          else
            Mem.create({:strength => 0.5,
                        :user_id => user_id,
                        :line_id => existing_line.id,
                        :status => true,
                        :review_after => Time.now})
          end

        else
          created_line = Line.create( :user_id => user_id,
                                :domid => dom_id,
                                :document_id => document_id )
          @@document_html.gsub!(
            /((?:<p|<li)[^>]*[^_]id="#{dom_id}"[^>]*line_id=")("[^>]*>)/) \
            {"#{$1}#{created_line.id}#{$2}"}
          @@document_html.gsub!(
            /((?:<p|<li)[^>]*line_id=")("[^>]*[^_]id="#{dom_id}"[^>]*>)/) \
            {"#{$1}#{created_line.id}#{$2}"}
          Mem.create({:strength => 0.5,
                      :user_id => user_id,
                      :line_id => created_line.id,
                      :status => true,
                      :review_after => Time.now})
        end
      elsif existing_line
        existing_line.delete 
        Mem.where(:line_id=>existing_line.id).delete_all
      end
    end
  end
end