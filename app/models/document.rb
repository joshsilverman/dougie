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
    new_nodes = params[:new_nodes] == 'true'
    document = Document.find(:first, :conditions => {:id => id, :user_id => user_id})

    if id.blank? || html.blank? || document.blank?
      return nil
    end

    # pull all existing document line
    existing_lines = document.lines

    deleted_lines = false
    Line.transaction do
      # general adjustments
      html_safe = "<li id=\"node_0\">#{html}</li>"
      html_safe = html_safe.gsub(/(\\[\w])+/i,"").gsub(/[\s]+/," ").gsub(/>\s</,"><").gsub(/<\/?(?:body|ul)[^>]*>/i,"").gsub(/<br>/,"").gsub(/<(\/?)LI([^>]*)>/,"<\\1li\\2>")
      html_safe.gsub!(/<p/i,"<li")
      html_safe.gsub!(/<\/p/,"</li")
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

      doc = Nokogiri::XML(html_safe)
      Line.update_all(doc,existing_lines,user_id) unless document.html.blank?
      Line.document_html = html
      if (new_nodes)
        Line.save_all(doc,document.id, user_id)
      end

      # delete lines/mems (don't use destory_all with dependencies) - half as many queries; tracks whether deleted
      deleted_lines = false
      unless delete_nodes == '[]' || delete_nodes.nil? || delete_nodes == ''
        deleted_lines = true
        # @todo delete_all does not need to act as tree here since child id's will be passed - not a big deal
        Line.delete_all(["id IN (?) AND document_id = ?", delete_nodes.split(','), document.id])
        Mem.delete_all(["line_id IN (?)", delete_nodes.split(',')]) # belongs in model but I think before_delete would delete mems infividually
      end
    end

    # update denormalized html and name
    document.update_attributes(:html => Line.document_html, :name => params[:name])
    
    # refresh existing if necessary
    if new_nodes || deleted_lines
      document.lines = Line.find_all_by_document_id(id)
    else
      document.lines = existing_lines
    end
    return document
  end
  
end
