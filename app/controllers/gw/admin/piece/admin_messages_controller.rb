# encoding: utf-8
class Gw::Admin::Piece::AdminMessagesController < ApplicationController
  include System::Controller::Scaffold
  layout 'base'
  
  def initialize_scaffold

  end
  
  def index
    item    = Gw::AdminMessage.new
    cond    = 'state = 1'
    order   = 'state ASC , sort_no ASC , updated_at DESC'
    @items  = item.find(:all, :conditions => cond, :order => order)
  end
end
