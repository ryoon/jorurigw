class Intra::Admin::MaintenancesController < ApplicationController
  include System::Controller::Scaffold
  
  def initialize_scaffold
  end
  
  def index
    item = Intra::Maintenance.new.readable
    item.page  params[:page], params[:limit]
    item.order params[:sort], 'published_at DESC'
    @items = item.find(:all)
    _index @items
  end
  
  def show
    @item = Intra::Maintenance.new.find(params[:id])
    return error_auth unless @item.readable?
    
    _show @item
  end

  def new
    @item = Intra::Maintenance.new({
      :state        => 'closed',
      :published_at => Core.now,
    })
  end
  
  def create
    @item = Intra::Maintenance.new(params[:item])
    _create @item
  end
  
  def update
    @item = Intra::Maintenance.new.find(params[:id])
    @item.attributes = params[:item]
    _update @item
  end
  
  def destroy
    @item = Intra::Maintenance.new.find(params[:id])
    _destroy @item
  end
  
  def item_to_xml(item, options = {})
    options[:include] = [:status]
    xml = ''; xml << item.to_xml(options) do |n|
      n << item.creator.to_xml(:root => 'creator', :skip_instruct => true, :include => [:user, :group]) if item.creator
    end
    return xml
  end
end
