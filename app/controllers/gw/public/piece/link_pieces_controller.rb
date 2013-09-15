class Gw::Public::Piece::LinkPiecesController < ApplicationController
  include System::Controller::Scaffold

  def index
    @piece_param = params['piece_param']
  end
end
