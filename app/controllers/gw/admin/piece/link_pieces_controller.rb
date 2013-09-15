# encoding: utf-8
class Gw::Admin::Piece::LinkPiecesController < ApplicationController
  include System::Controller::Scaffold
  layout 'base'
  
  def index
    @piece_param = params['piece_param']
    
    item = Gw::EditLinkPiece.new
    cond  = "published = 'opened' and state = 'enabled' and id = #{@piece_param.to_i}"
    order = "state DESC,sort_no"
    @items = item.find(:all, :order => order, :conditions => cond, 
      :include => [:css, :icon, 
        :opened_children => [:css, :icon, :parent, 
          :opened_children => [:css, :icon, :parent]]])
  end
end
