class Pref::Public::RecentDocsController < ApplicationController
  include Pref::Controller::Feed
  
  def index
    doc = Pref::Doc.new.public
    doc.visible_in_list
    doc.page 1, 50
    @docs = doc.find(:all, :order => 'published_at DESC')
    return true if render_feed @docs
  end
end
