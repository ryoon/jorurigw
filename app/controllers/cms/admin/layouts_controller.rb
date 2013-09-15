class Cms::Admin::LayoutsController < ApplicationController
  include System::Controller::Scaffold
  include System::Controller::Scaffold::Publication
  include System::Controller::Scaffold::Commitment
  
  def initialize_scaffold
  end
  
  def index
    item = Cms::Layout.new#.readable
    item.page  params[:page], params[:limit]
    item.order params[:sort], :name
    @items = item.find(:all)
    _index @items
  end
  
  def show
    @item = Cms::Layout.new.find(params[:id])
    return error_auth unless @item.readable?
    
    _show @item
  end

  def new
    @item = Cms::Layout.new({
      :state      => 'public',
    })
  end
  
  def create
    @item = Cms::Layout.new(params[:item])
    _create @item
  end
  
  def update
    @item = Cms::Layout.new.find(params[:id])
    @item.attributes = params[:item]
    _update @item
  end
  
  def destroy
    @item = Cms::Layout.new.find(params[:id])
    _destroy @item
  end
  
  def item_to_xml(item, options = {})
    options[:include] = [:status, :publisher]
    xml = ''; xml << item.to_xml(options) do |n|
      n << item.creator.to_xml(:root => 'creator', :skip_instruct => true, :include => [:user, :group]) if item.creator
      n << item.recognizers.to_xml(:root => 'recognizers', :skip_instruct => true, :include => [:user]) if item.recognizers
    end
    return xml
  end
end
