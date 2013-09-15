class Pref::Public::Piece::RecentDocsController < ApplicationController
  def index
    doc = Pref::Doc.new.public
    doc.visible_in_recent
    doc.page 1, 10
    @docs = doc.find(:all, :order => 'published_at DESC')
  end
end
