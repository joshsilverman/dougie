class Document < ActiveRecord::Base

  validates :name, :length => {:minimum => 1,
                               :maximum => 30,
                               :message => "Name must be between 1-30 characters"},
                   :format => {:with => /[a-zA-Z0-9-&%$\#+\(\)*^@!]/,
                               :message => "Pleas use only letters numbers and (!@#\$%^&*-+)"}

  include DocumentsHelper

  has_many :lines, :dependent => :destroy

  belongs_to :tag
  belongs_to :user

  def self.update(params, user_id)

    id = params[:id]
    html = params[:html]
    delete_nodes = params[:delete_nodes]
    document = Document.find(:first, :conditions => {:id => id, :user_id => user_id})
    return nil if id.blank? || html.nil? || document.blank?

    Line.transaction do
      html_safe = "<li>#{html}</li>"
      html_safe = html_safe.gsub(/(\\[\w])+/i,"").gsub(/[\s]+/," ").gsub(/>\s</,"><").gsub(/<\/?(?:body|ul)[^>]*>/i,"").gsub(/<br>/,"").gsub(/<(\/?)LI([^>]*)>/,"<\\1li\\2>")
      html_safe.gsub!(/<p/i,"<li")
      html_safe.gsub!(/<\/p/,"</li")
      html_safe.gsub!(/<div/i,"<li")
      html_safe.gsub!(/<\/div/,"</li")
      # @browser ie adjustments
      html_safe.gsub!(/(<[^>]* line_id)( [^>]*>)/, "\\1=\"\"\\2")
      html_safe.gsub!(/(<[^>]*id=)([^\\"=]*)( [^=]*=[^>]*)?>/, "\\1\"\\2\"\\3>")
      html_safe.gsub!(/(<[^>]*class=)([^\\"=]*)( [^=]*=[^>]*)?>/, "\\1\"\\2\"\\3>")
      # make sure there are no empty nodes
      html_safe.gsub!(/(<li[^>]*>)(<\/li[^>]*>)/i, "\\1 \\2")
      html_safe.gsub!(/(<li[^>]*>)(<\/li[^>]*>)/i, "\\1 \\2")
      html_safe.gsub!(/(<li[^>]*>)(<li[^>]*>)/i, "\\1 \\2")
      html_safe.gsub!(/(<li[^>]*>)(<li[^>]*>)/i, "\\1 \\2")
      # remove all extraneous span tags usually originating from copy/paste
      html_safe.gsub!(/<\/?(?:span|a|meta|i|b|img|u|sup)[^>]*>/i, "")
      html_safe.gsub!(/\\"/, "\"")

      doc = Nokogiri::XML(html_safe)
      Line.document_html = html
      Line.save_all(doc,document.id, user_id)

      # delete lines/mems (don't use destory_all with dependencies) - half as many queries; tracks whether deleted
      unless delete_nodes == '[]' || delete_nodes.nil? || delete_nodes == ''
        Line.delete_all(["id IN (?) AND document_id = ? AND user_id = ?", delete_nodes.split(','), document.id, user_id])
        Mem.delete_all(["line_id IN (?) AND user_id = ?", delete_nodes.split(','), user_id]) # belongs in model but I think before_delete would delete mems infividually
      end
    end

    document.update_attributes(:html => Line.document_html)
    document.update_attributes(:name => params[:name])
    return document
  end
  
end