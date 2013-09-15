class System::Admin::AdminLogsController < ApplicationController
  include System::Controller::Scaffold
  
  def index
    item = System::AdminLog.new#.readable
    item.page  params[:page], params[:limit]
    item.order params[:sort], 'id DESC'
    @items = item.find(:all)
    _index @items
  end
  
  def show
    @item = System::AdminLog.new.find(params[:id])
    return error_auth unless @item#.readable?
    
    _show @item
  end
end
