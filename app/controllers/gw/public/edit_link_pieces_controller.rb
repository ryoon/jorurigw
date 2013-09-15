class Gw::Public::EditLinkPiecesController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold

  end

  def init_params
    @is_gw_admin = Gw.is_admin_admin?
    @role_developer = Gw::EditLinkPiece.is_dev?(Site.user.id)
    @edit_link_piece_admin     = Gw::EditLinkPiece.is_admin?(Site.user.id)
    @edit_link_piece_editor  = Gw::EditLinkPiece.is_editor?(Site.user.id)
    @u_role = @role_developer || @edit_link_piece_admin || @edit_link_piece_editor || @is_gw_admin

    pid      = params[:pid] == '0' ? 1 : params[:pid]
    @parent = Gw::EditLinkPiece.find_by_id(pid)

    if @parent.blank?
      @pid = params[:pid]
      @p_level_no = 1
    else
      @pid = @parent.id
      @p_level_no = @parent.level_no
    end

    params[:limit] = nz(params[:limit],30)
  end

  def index
    init_params
    return authentication_error(403) unless @u_role==true
    return http_error(404) if !@parent.blank? && @parent.uid != nil

    item = Gw::EditLinkPiece.new
    item.page  params[:page], params[:limit]
    cond  = "state != 'deleted' and parent_id = #{@pid} and uid is null"
    order = "sort_no"
    @items = item.find(:all,:order=>order,:conditions=>cond)
    _index @items
  end

  def show
    init_params
    return authentication_error(403) unless @u_role==true

    @item = Gw::EditLinkPiece.find_by_id(params[:id])
    return http_error(404) if @item.uid != nil
  end

  def new
    init_params
    return authentication_error(403) unless @u_role==true
    return http_error(404) if !@parent.blank? && @parent.uid != nil

    cond  = "state!='deleted' and parent_id=#{@pid}"
    order = "sort_no DESC"
    max_sort = Gw::EditLinkPiece.find(:first , :order=>order , :conditions=>cond)
    if max_sort.blank?
      max_sort_no = 0
    else
      max_sort_no = max_sort.sort_no
    end
    @item = Gw::EditLinkPiece.new
    @item.parent_id       = @pid
    @item.level_no        = @parent.blank? ? 1 : @parent.level_no + 1
    @item.state           = 'enabled'
    @item.published       = 'opened'
    @item.tab_keys        = 0
    @item.sort_no         = max_sort_no.to_i + 10
    @item.class_created   = 1
    @item.class_external  = 1
    @item.class_sso       = 1
  end
  def create
    init_params
    return authentication_error(403) unless @u_role==true
    @item = Gw::EditLinkPiece.new(params[:item])
    return http_error(404) if @item.uid != nil
    location = "#{Site.current_node.public_uri}?pid=#{@pid}"
    options = {
      :success_redirect_uri => location
    }
    _create @item,options
  end

  def edit
    init_params
    return authentication_error(403) unless @u_role==true
    return http_error(404) if !@parent.blank? && @parent.uid != nil

    @item = Gw::EditLinkPiece.find_by_id(params[:id])
    return http_error(404) if @item.uid != nil
  end
  def update
    init_params
    @item = Gw::EditLinkPiece.find_by_id(params[:id])
    return http_error(404) if @item.uid != nil
    @item.attributes = params[:item]
    location = "#{Site.current_node.public_uri}#{@item.id}?pid=#{@pid}"
    options = {
      :success_redirect_uri => location
    }
    _update @item,options
  end

  def destroy
    init_params
    return authentication_error(403) unless @u_role==true

    item = Gw::EditLinkPiece.find_by_id(params[:id])
    return http_error(404) if item.uid != nil
    item.published      = 'closed'
    item.state          = 'deleted'
    item.tab_keys       = nil
    item.sort_no        = nil
    item.deleted_at     = Time.now
    item.deleted_user   = Site.user.name
    item.deleted_group  = Site.user_group.name
    item.save(false)
    location = "#{Gw.chop_with(Site.current_node.public_uri,'/')}?pid=#{@pid}"
    redirect_to location
    return

  end

  def updown
    init_params
    return authentication_error(403) unless @u_role==true
    return http_error(404) if !@parent.blank? && @parent.uid != nil

    item = Gw::EditLinkPiece.find_by_id(params[:id])
    return http_error(404) if item.uid != nil
    if item.blank?
      location = Gw.chop_with(Site.current_node.public_uri,'/')+"?pid=#{@pid}"
      redirect_to location
      return
    end

    updown = params[:order]

    case updown
    when 'up'
      cond  = "state!='deleted' and parent_id=#{@pid} and sort_no < #{item.sort_no} "
      order = " sort_no DESC "
      item_rep = Gw::EditLinkPiece.find(:first,:conditions=>cond,:order=>order)
      return http_error(404) if item_rep.uid != nil
      if item_rep.blank?
      else
        sort_work = item_rep.sort_no
        item_rep.sort_no = item.sort_no
        item.sort_no = sort_work
        item.save(false)
        item_rep.save(false)
      end
    when 'down'
      cond  = "state!='deleted' and parent_id=#{@pid} and sort_no > #{item.sort_no} "
      order = " sort_no ASC "
      item_rep = Gw::EditLinkPiece.find(:first,:conditions=>cond,:order=>order)
      return http_error(404) if item_rep.uid != nil
      if item_rep.blank?
      else
        sort_work = item_rep.sort_no
        item_rep.sort_no = item.sort_no
        item.sort_no = sort_work
        item.save(false)
        item_rep.save(false)
      end
    else
    end

    location = Gw.chop_with(Site.current_node.public_uri,'/')+"?pid=#{@pid}"
    redirect_to location
    return
  end

  def swap
    init_params
    return authentication_error(403) unless @u_role==true
    return http_error(404) if !@parent.blank? && @parent.uid != nil

    item1 = Gw::EditLinkPiece.find(params[:id]) rescue nil
    item2 = Gw::EditLinkPiece.find(params[:sid]) rescue nil
    return http_error(404) if item1.blank? || item1.deleted? || item1.uid != nil
    return http_error(404) if item2.blank? || item2.deleted? || item2.uid != nil

    Gw::EditLinkPiece.swap(item1, item2)

    location = Gw.chop_with(Site.current_node.public_uri,'/')+"?pid=#{@pid}"
    redirect_to location
  end

  def list
    init_params
    return authentication_error(403) unless @u_role==true
    return http_error(404) if !@parent.blank? && @parent.uid != nil

    item = Gw::EditLinkPiece.new
    cond  = "state!='deleted' and level_no=2 and uid is null"
    order = "state DESC,sort_no"
    @items = item.find(:all,:order=>order,:conditions=>cond)
  end

end
