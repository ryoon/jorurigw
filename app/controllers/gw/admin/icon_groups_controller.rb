class Gw::Admin::IconGroupsController < ApplicationController
  include System::Controller::Scaffold
  def index
    item = Gw::IconGroup.new
    item.page  params[:page], params[:limit]
    @items = item.find(:all)
  end
  def show
    @item = Gw::IconGroup.find(params[:id])
  end
  def new
    @item = Gw::IconGroup.new({})
  end
  def create
    @item = Gw::IconGroup.new(params[:item])
    _create @item
  end
  def edit
    @item = Gw::IconGroup.find_by_id(params[:id])
  end
  def update
    @item = Gw::IconGroup.find(params[:id])
    @item.attributes = params[:item]
    _update @item
  end
  def destroy
    @item = Gw::IconGroup.find(params[:id])
    _destroy @item
  end
end
