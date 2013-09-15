class Gw::Public::Piece::IndLeftPiecesController < ApplicationController
  include System::Controller::Scaffold
  
  def index
    @items = Gw::IndPortalPiece.get_user_items
    @items = @items.select{|x| x.position == 'left'} unless @items.blank?
    @setting = Gw::IndPortalSetting.read
    @link_items = Gw::EditLinkPiece.get_user_items
    @blog_items = Gw::BlogPart.get_user_items
    _index @link_items + @blog_items
  end
end