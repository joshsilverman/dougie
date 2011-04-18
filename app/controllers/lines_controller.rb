class LinesController < ApplicationController

  def update

    line = Line.where(:id => params[:line][:id], :user_id => current_user.id).first
    if line

      #update denormalized html in documents table
      document = Document.find_by_id(line.document_id)
      html = document.html
      html = html.gsub(/((?:<p|<li)[^>]*line_id="#{params[:line][:id]}"[^>]*>)[^>]*</) {"#{$1}#{params[:line][:text]}<"}
      document.update_attribute(:html, html)

      render :json => {:line => params[:line][:text], :html => document.html}
    else
      render :nothing => true, :status => 400
    end

  end

end
