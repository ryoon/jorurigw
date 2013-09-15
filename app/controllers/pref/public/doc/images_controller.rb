class Pref::Public::Doc::ImagesController < ApplicationController
  def show
    doc = Pref::Doc.new.public
    doc.and :name, params[:name]
    return http_error(404) unless @doc = doc.find(:first)
    
    file = Pref::DocImage.new
    file.and :doc_id, @doc.id
    file.and :name,   params[:file] + '.' + params[:format]
    return http_error(404) unless @file = file.find(:first)
    
    f = open(@file.upload_path)
    send_data(f.read, {:type => @file.content_type, :filename => @file.name, :disposition => 'inline'})
    f.close
  end
end
