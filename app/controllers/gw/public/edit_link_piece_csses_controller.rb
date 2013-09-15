class Gw::Public::EditLinkPieceCssesController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold

  end

  def init_params
    params[:limit] = nz(params[:limit],30)
    @is_gw_admin = Gw.is_admin_admin?

    @role_developer = Gw::EditLinkPiece.is_dev?(Site.user.id)
    @edit_link_piece_admin     = Gw::EditLinkPiece.is_admin?(Site.user.id)
    @edit_link_piece_editor  = Gw::EditLinkPiece.is_editor?(Site.user.id)
    @u_role = @role_developer || @edit_link_piece_admin || @edit_link_piece_editor || @is_gw_admin
  end

  def index
    init_params
    return authentication_error(403) unless @u_role==true

    item = Gw::EditLinkPieceCss.new
    item.page  params[:page], params[:limit]

    order = "css_sort_no"
    @items = item.find(:all, :order=>order, :conditions=>"")
    _index @items
  end

  def show
    init_params
    return authentication_error(403) unless @u_role==true
    @item = Gw::EditLinkPieceCss.find(params[:id])
  end

  def new
    init_params
    return authentication_error(403) unless @u_role==true

    cond  = "state != 'deleted'"
    order = "css_sort_no DESC"
    max_sort = Gw::EditLinkPieceCss.find(:first , :order=>order , :conditions=>cond)
    if max_sort.blank?
      max_css_sort_no = 0
    else
      max_css_sort_no = max_sort.css_sort_no
    end
    @item = Gw::EditLinkPieceCss.new
    @item.state           = 'enabled'
    @item.css_sort_no         = max_css_sort_no.to_i + 10

  end
  def create
    init_params
    return authentication_error(403) unless @u_role==true

    @item = Gw::EditLinkPieceCss.new(params[:item])
    location = "#{Site.current_node.public_uri}"
    options = {
      :success_redirect_uri => location
    }
    @item.created_user   = Site.user.name
    @item.created_group  = Site.user_group.name
    _create @item,options
  end

  def edit
    init_params
    return authentication_error(403) unless @u_role==true

    @item = Gw::EditLinkPieceCss.find_by_id(params[:id])
  end
  def update
    init_params

    @item = Gw::EditLinkPieceCss.find_by_id(params[:id])
    @item.attributes = params[:item]
    location = "#{Site.current_node.public_uri}#{@item.id}"
    options = {
      :success_redirect_uri => location
    }

    @item.updated_user   = Site.user.name
    @item.updated_group  = Site.user_group.name
    _update @item,options
  end

  def destroy
    init_params
    return authentication_error(403) unless @u_role==true

    item = Gw::EditLinkPieceCss.find_by_id(params[:id])
    item.state          = 'deleted'
    item.css_sort_no    = nil
    item.deleted_at     = Time.now
    item.deleted_user   = Site.user.name
    item.deleted_group  = Site.user_group.name
    location = "#{Gw.chop_with(Site.current_node.public_uri,'/')}"
    _update item, :success_redirect_uri => location, :notice => "#{item.css_name}の削除に成功しました"

  end

end
