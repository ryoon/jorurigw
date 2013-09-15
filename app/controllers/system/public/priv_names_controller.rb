class System::Public::PrivNamesController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
    @css = %w(/layout/admin/style.css)
  end

  def index
    init_params
    return authentication_error(403) unless @is_dev
    item = System::PrivName.new
    item.page  params[:page], params[:limit]
    @items = item.find(:all, :order => [:sort_no])
  end

  def show
    init_params
    return authentication_error(403) unless @is_dev
    @item = System::PrivName.find(params[:id])
  end

  def new
    init_params
    return authentication_error(403) unless @is_dev
    @item = System::PrivName.new({
      :state => 'public'
      })
  end

  def create
    init_params
    return authentication_error(403) unless @is_dev
    @item = System::PrivName.new(params[:item])
    location = Gw.chop_with("#{Site.current_node.public_uri}",'/')
    options = {
      :success_redirect_uri=>location
      }
    _create(@item,options)
  end

  def edit
    init_params
    return authentication_error(403) unless @is_dev
    @item = System::PrivName.find_by_id(params[:id])
  end

  def update
    init_params
    return authentication_error(403) unless @is_dev
    @item = System::PrivName.new.find(params[:id])
    @item.attributes = params[:item]
    location = Gw.chop_with("#{Site.current_node.public_uri}",'/')
    options = {
      :success_redirect_uri=>location
      }
    _update(@item,options)
  end

  def destroy
    init_params
    return authentication_error(403) unless @is_dev
    @item = System::PrivName.new.find(params[:id])
    location = Gw.chop_with("#{Site.current_node.public_uri}",'/')
    options = {
      :success_redirect_uri=>location
      }
    _destroy(@item,options)
  end

  def init_params
    @is_dev = System::Role.is_dev?
    @is_admin = System::Role.is_admin?
  end

end
