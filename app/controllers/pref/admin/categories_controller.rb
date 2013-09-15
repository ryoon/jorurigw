class Pref::Admin::CategoriesController < ApplicationController
  include System::Controller::Scaffold
  
  def initialize_scaffold
    @max_level = 2
    
    id = params[:parent]
    if id == '0'
      @parent = Pref::Category.new()
      @parent.id = 0
      @parent.level_no = 0
    else
      @parent = Pref::Category.new.find(id)
    end
  end
  
  def index
    item = Pref::Category.new#.readable
    item.and :parent_id, @parent
    item.page  params[:page], params[:limit]
    item.order params[:sort], :sort_no
    @items = item.find(:all)
    _index @items
  end
  
  def show
    @item = Pref::Category.new.find(params[:id])
    return error_auth unless @item.readable?
    
    _show @item
  end

  def new
    @item = Pref::Category.new({
      :state      => 'public',
      :sort_no    => 1,
    })
  end
  
  def create
    @item = Pref::Category.new(params[:item])
    @item.parent_id = @parent.id
    @item.level_no  = @parent.level_no + 1
    _create @item
  end
  
  def update
    @item = Pref::Category.new.find(params[:id])
    @item.attributes = params[:item]
    _update @item
  end
  
  def destroy
    @item = Pref::Category.new.find(params[:id])
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
