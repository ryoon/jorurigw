class System::Admin::RolesController < ApplicationController
  include System::Controller::Scaffold

  def index
    item = System::Role.new
    item.page  params[:page], params[:limit]
    @items = item.find(:all, :order => [:table_name, :priv_name, :idx].join(','))
  end

  def show
    @item = System::Role.find(params[:id])
  end

  def new
    @item = System::Role.new({})
  end

  def create
    conv_uidraw_to_uid
    @item = System::Role.new(params[:item])
    _create @item
  end

  def edit
    @item = System::Role.find_by_id(params[:id])
  end

  def update
    conv_uidraw_to_uid
    @item = System::Role.new.find(params[:id])
    @item.attributes = params[:item]
    _update @item
  end

  def conv_uidraw_to_uid()
    params[:item]['uid'] = ( params[:item]['class_id'] == '1' ? params[:item]['uid_raw'] : params[:item]['gid_raw']) if nz(params[:item]['class_id'],'') != ''
    params[:item].delete 'uid_raw'
    params[:item].delete 'gid_raw'
  end

  def destroy
    @item = System::Role.new.find(params[:id])
    _destroy @item
  end

end
