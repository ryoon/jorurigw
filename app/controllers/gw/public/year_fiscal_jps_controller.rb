class Gw::Public::YearFiscalJpsController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold

    return redirect_to(request.env['PATH_INFO']) if params[:reset]
    _search_condition

#    error_auth unless params[:content]
#    error_auth unless (@content = Cms::Content.find(params[:content]))

    params[:limit] = nz(params[:limit], 10)
    @limit = params[:limit]

  end
  def _search_condition
  end

  def index
    init_params
    return authentication_error(403) unless @is_admin==true

    item = Gw::YearFiscalJp.new
    item.search params
    item.page   params[:page], params[:limit]
    item.order "start_at DESC"
    @items = item.find(:all)
  end
  def show
    init_params
    return authentication_error(403) unless @is_admin==true

    @item = Gw::YearFiscalJp.find(params[:id])
  end

  def new
    init_params
    return authentication_error(403) unless @is_admin==true

    @item = Gw::YearFiscalJp.new
  end
  def create
    init_params
    return authentication_error(403) unless @is_admin==true

    @item = Gw::YearFiscalJp.new(params[:item])
    location = Gw.chop_with("#{Site.current_node.public_uri}",'/')
    options = {
      :success_redirect_uri=>location
    }
    _create(@item,options)
  end

  def edit
    init_params
    return authentication_error(403) unless @is_admin==true

    @item = Gw::YearFiscalJp.find(params[:id])
  end
  def update
    init_params
    return authentication_error(403) unless @is_admin==true

    @item = Gw::YearFiscalJp.new.find(params[:id])
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

    @item = Gw::YearFiscalJp.new.find(params[:id])
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
