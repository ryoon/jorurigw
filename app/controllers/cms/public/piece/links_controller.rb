class Cms::Public::Piece::LinksController < ApplicationController
  def index
    item = Cms::PieceLink.new.public
    item.piece_id = Site.current_piece.id
    @items = item.find(:all, :order => :sort_no)
  end
end
