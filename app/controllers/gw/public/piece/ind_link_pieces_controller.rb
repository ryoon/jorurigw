class Gw::Public::Piece::IndLinkPiecesController < ApplicationController
  include System::Controller::Scaffold
  
  def index
    @items = Gw::EditLinkPiece.get_user_items
    _index @items
  end
end
