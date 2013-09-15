class Cms::Admin::MapsController < ApplicationController
  include System::Controller::Scaffold
  
  def initialize_scaffold
    id      = params[:parent] == '0' ? 1 : params[:parent]
    @parent = Cms::Map.new.find(id)
  end
  
  def index
    item = Cms::Map.new#.readable
    item.parent_id = @parent.id
    item.page  params[:page], params[:limit]
    item.order params[:sort], :sort_no
    @items = item.find(:all)
    _index @items
  end
  
  def show
    @item = Cms::Map.new.find(params[:id])
    return error_auth unless @item.readable?
    
    _show @item
  end

  def new
    @item = Cms::Map.new({
      :state      => 'public',
      :sort_no    => 1,
      :parent_id  => @parent.id,
    })
  end
  
  def create
    @item = Cms::Map.new(params[:item])
    @item.parent_id = @parent.id
    _create @item
  end
  
  def update
    @item = Cms::Map.new.find(params[:id])
    @item.attributes = params[:item]
    _update @item
  end
  
  def destroy
    @item = Cms::Map.new.find(params[:id])
    _destroy @item
  end
  
  def item_to_xml(item, options = {})
    options[:include] = [:status, :node]
    xml = ''; xml << item.to_xml(options) do |n|
      n << item.creator.to_xml(:root => 'creator', :skip_instruct => true, :include => [:user, :group]) if item.creator
    end
    return xml
  end
end
