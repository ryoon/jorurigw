class Cms::Admin::TmpFileGroupsController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
    self.class.layout 'admin/base'

    @tmp = params[:tmp]
  end

  def index
    item = Cms::TmpFileGroup.new#.readable
    item.and :tmp_id, @tmp
    item.page  params[:page], params[:limit]
    item.order params[:sort], :name
    @items = item.find(:all)
    _index @items
  end

  def show
    @item = Cms::TmpFileGroup.new.find(params[:id])
    return error_auth unless @item.readable?

    _show @item
  end

  def new
    @item = Cms::TmpFileGroup.new({
    })
  end

  def create
    @item = Cms::TmpFileGroup.new(params[:item])
    @item.tmp_id = @tmp
    _create @item
  end

  def update
    @item = Cms::TmpFileGroup.new.find(params[:id])
    @item.attributes = params[:item]
    _update @item
  end

  def destroy
    @item = Cms::TmpFileGroup.new.find(params[:id])
    _destroy @item
  end

end
