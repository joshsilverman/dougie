class LinesController < ApplicationController

  def update

    line = Line.where(:id => params[:line][:id], :user_id => current_user.id).first
    if line

      # update line
      line.update_attribute(:text, params[:line][:text])

      #update denormalized html in documents table
      document = Document.find_by_id(line.document_id)
      html = document.html
      html = html.gsub(/((?:<p|<li)[^>]*line_id="#{params[:line][:id]}"[^>]*>)[^>]*</) {"#{$1}#{params[:line][:text]}<"}
      document.update_attribute(:html, html)

      render :json => line
    else
      render :nothing => true, :status => 400
    end

  end

end
