class Gw::Public::AdminMessagesController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
#    @css = %w(/_common/themes/gw/css/admin_settings.css)
  end

  def index
    init_params
    return authentication_error(403) unless @is_admin==true

    item    = Gw::AdminMessage.new
    order   = 'state ASC , sort_no ASC , updated_at DESC'
    @items  = item.find(:all,:order=>order)
  end
  def show
    init_params
    return authentication_error(403) unless @is_admin==true

    @item = Gw::AdminMessage.find(params[:id])
  end

  def new
    init_params
    return authentication_error(403) unless @is_admin==true

    @item = Gw::AdminMessage.new
    @item.state = 2
    item = Gw::AdminMessage.find(:first,:order=>'sort_no DESC')
    if item.blank?
      init_sort_no = 10
    else
      init_sort_no = item.sort_no
    end
    @item.sort_no = init_sort_no+10
  end
  def create
    init_params
    return authentication_error(403) unless @is_admin==true

    @item = Gw::AdminMessage.new(params[:item])
    location = Gw.chop_with("#{Site.current_node.public_uri}",'/')
    options = {
      :success_redirect_uri=>location
    }
    _create(@item,options)
  end

  def edit
    init_params
    return authentication_error(403) unless @is_admin==true

    @item = Gw::AdminMessage.find(params[:id])
  end
  def update
    init_params
    return authentication_error(403) unless @is_admin==true
    @item = Gw::AdminMessage.new.find(params[:id])
    @item.attributes = params[:item]
    location = "#{Site.current_node.public_uri}#{params[:id]}"
    options = {
      :success_redirect_uri=>location
    }
    _update(@item,options)
  end

  def destroy
    init_params
    return authentication_error(403) unless @is_admin==true
    @item = Gw::AdminMessage.new.find(params[:id])
    location = Gw.chop_with("#{Site.current_node.public_uri}",'/')
    options = {
      :success_redirect_uri=>location
    }
    _destroy(@item,options)
  end
  def init_params
    @is_admin = Gw::AdminMessage.is_admin?( Site.user.id )
  end

end
