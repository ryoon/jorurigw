class Pref::Admin::DepartmentsController < ApplicationController
  include System::Controller::Scaffold
  
  def initialize_scaffold
  end
  
  def index
    item = Pref::Department.new.readable
    item.page  params[:page], params[:limit]
    item.order params[:sort], :sort_no
    @items = item.find(:all)
    _index @items
  end
  
  def show
    @item = Pref::Department.new.find(params[:id])
    return error_auth unless @item.readable?
    
    _show @item
  end

  def new
    @item = Pref::Department.new({
      :state      => 'enabled',
    })
  end
  
  def create
    @item = Pref::Department.new(params[:item])
    _create @item
  end
  
  def update
    @item = Pref::Department.new.find(params[:id])
    @item.attributes = params[:item]
    _update @item
  end
  
  def destroy
    @item = Pref::Department.new.find(params[:id])
    _destroy @item
  end
  
  def item_to_xml(item, options = {})
    options[:include] = [:status, :sections]
    item.to_xml(options)
  end
end
