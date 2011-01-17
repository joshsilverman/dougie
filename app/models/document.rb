class Document < ActiveRecord::Base

  include DocumentsHelper

  has_many :lines, :dependent => :destroy

  belongs_to :tag
  belongs_to :user

  def self.update(params, current_user)

    id = params[:id]
    html = params[:html]
    delete_nodes = params[:delete_nodes]
    new_nodes = params[:new_nodes] == 'true'
    document = current_user.documents.find_by_id(id)
#    document = Document.includes(:lines).where(:id => id, :user_id => current_user.id).first //@todo combind existing lines query with this one

    if id.blank? || html.blank? || document.blank?
      return nil
    end

    # pull all existing document line
    existing_lines = document.lines

    # group transaction; track whether lines deleted
    deleted_lines = false
    Line.transaction do

      # efficient find or create root using previous query
      root = nil
      existing_lines.each do |line|
        if line.domid == "node_0"
          root = line
          break
        end
      end
      if root.nil?
        root = Line.create(:document_id => document.id,:domid => "node_0",:text => "root" )
      end

      # run update line; store whether anything was changed
      dp = DocumentParser.new(html)
      Line.update_line(dp.doc,existing_lines) unless document.html.blank?

      Line.document_html = html
      if (new_nodes)
        Line.preorder_save(dp.doc,document.id, {'node_0' => root})
      end

      # update denormalized html and name
      document.update_attributes(:html => Line.document_html, :name => params[:name])

      # delete lines/mems (don't use destory_all with dependencies) - half as many queries; tracks whether deleted
      deleted_lines = false
      unless delete_nodes == '[]' || delete_nodes.nil? || delete_nodes == ''
        deleted_lines = true
        Line.delete_all(["id IN (?) AND document_id = ?", delete_nodes.split(','), document.id])
        Mem.delete_all(["line_id IN (?)", delete_nodes.split(',')]) # belongs in model but I think before_delete would delete mems infividually
      end
    end

    # refresh existing if necessary
    if new_nodes || deleted_lines
      document.lines = Line.find_all_by_document_id(id)
    else
      document.lines = existing_lines
    end

    return document
    
  end
  
end
