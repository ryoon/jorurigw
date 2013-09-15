class Gw::Public::Piece::BlogPartsController < ApplicationController
  include System::Controller::Scaffold
  
  def index
    @items = Gw::BlogPart.get_user_items
    _index @items
  end
end
