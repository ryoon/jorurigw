class Gw::Public::Piece::RssReadersController < ApplicationController
  include System::Controller::Scaffold
  
  def index
    @items = Gw::RssReader.get_user_items
    _index @items
  end
end
