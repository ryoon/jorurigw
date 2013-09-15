class Pref::Public::DocsController < ApplicationController
  include Pref::Controller::Feed
  
  def index
    return redirect_to(request.env['PATH_INFO']) if params[:reset]
    
    #Site.current_item = nil
    
    doc = Pref::Doc.new.public
    doc.and 'language_id', 1
    doc.search params
    doc.page params[:page], 50
    @items = doc.find(:all, :order => 'published_at DESC')
    return true if render_feed @items
    
    # TODO Control the domains.
    render :action => :index_mobile if Site.mobile
  end
  
  def show
    item = Pref::Doc.new.public
    item.and :name, params[:name]
    
    return http_error(404) unless @item = item.find(:first)
    
    Site.current_item = @item
    Page.title        = @item.title
    
    # TODO Control the domains.
    render :action => :show_mobile if Site.mobile
  end
end
