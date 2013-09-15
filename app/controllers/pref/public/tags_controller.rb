class Pref::Public::TagsController < ApplicationController
  include Pref::Controller::Feed
  
  def index
    return redirect_to(request.env['PATH_INFO']) if params[:reset]
    
    @tag = params[:name]
    
    doc = Pref::Doc.new.public
    doc.and 'language_id', 1
    join = "inner join system_tags USING(unid)"
    doc.and "system_tags.word", @tag
    doc.page params[:page], 50
    @items = doc.find(:all, :joins => join, :order => 'published_at DESC')
    return true if render_feed @items
  end
end
