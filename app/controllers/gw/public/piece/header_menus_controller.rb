class Gw::Public::Piece::HeaderMenusController < ApplicationController
  include System::Controller::Scaffold

  def index
    @piece_param = params['piece_param']
  end
end
