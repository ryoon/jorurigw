class Gwsub::Public::Sb04::Sb04EditableDatesController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
    return redirect_to(request.env['PATH_INFO']) if params[:reset]
  end

  def index
    init_params
    item = Gwsub::Sb04EditableDate.new #.readable
    item.search params
    item.page   params[:page], params[:limit]
    item.order  params[:id], @sort_keys
    @items = item.find(:all)
    _index @items
  end
  def show
    init_params
    @item = Gwsub::Sb04EditableDate.find_by_id(params[:id])
    return http_error(404) if @item.blank?
  end

  def new
    init_params

    @l3_current = '03'
    @item = Gwsub::Sb04EditableDate.new
  end
  def create
    init_params

    @l3_current = '03'
    new_item = Gwsub::Sb04EditableDate.set_f(params[:item])
    @item = Gwsub::Sb04EditableDate.new(new_item)
    location = Gw.chop_with("#{Site.current_node.public_uri}",'/').to_s
    location << "?#{@qs}" unless @qs.blank?
    options = {
      :success_redirect_uri=>location,
    }
    _create(@item,options)
  end

  def edit
    init_params
    @item = Gwsub::Sb04EditableDate.find_by_id(params[:id])
    return http_error(404) if @item.blank?
  end
  def update
    init_params

    @item = Gwsub::Sb04EditableDate.find(params[:id])
    new_item = Gwsub::Sb04EditableDate.set_f(params[:item])
    @item.attributes = new_item
    location = "#{Site.current_node.public_uri}#{@item.id}"
    location << "?#{@qs}" unless @qs.blank?
    options = {
      :success_redirect_uri=>location,
    }
    _update(@item,options)
  end

  def destroy
    init_params

    @item = Gwsub::Sb04EditableDate.find_by_id(params[:id])
    return http_error(404) if @item.blank?
    location = Gw.chop_with("#{Site.current_node.public_uri}",'/').to_s
    location << "?#{@qs}" unless @qs.blank?
    options = {
      :success_redirect_uri=>location
    }
    _destroy(@item,options)
  end

  def init_params
    # ユーザー権限設定
    @role_developer  = Gwsub::Sb04stafflist.is_dev?(Site.user.id)
    @role_admin      = Gwsub::Sb04stafflist.is_admin?(Site.user.id)
    @u_role = @role_developer || @role_admin

    # 管理者以外には見せない
    return authentication_error(403) unless @u_role==true

    @menu_header3 = 'sb0404menu'
    @menu_title3  = 'コード管理'
    @menu_header4 = 'sb04_editable_dates'
    @menu_title4  = '期限設定'

    # 年度選択　設定
#    @fyed_id = Gwsub.set_fyear_select(params[:fyed_id])
    @fyed_id = nz(params[:fyed_id],0)
    # 表示行数　設定
    @limits = nz(params[:limit],30)

    search_condition
    sortkeys_setting
    @css = %w(/_common/themes/gw/css/gwsub.css)
    @l1_current = '05'
    @l2_current = '01'
    @l3_current = '01'
  end

  def search_condition
    params[:fyed_id]  = nz(params[:fyed_id], @fyed_id)
    params[:limit]    = nz(params[:limit], @limits)
    @s_keyword = nil
    @s_keyword = params[:s_keyword] unless params[:s_keyword].blank?

    qsa = ['limit', 's_keyword' ,'fyed_id']
    @qs = qsa.delete_if{|x| nz(params[x],'')==''}.collect{|x| %Q(#{x}=#{params[x]})}.join('&')
  end
  def sortkeys_setting
    @sort_keys = nz(params[:sort_keys], 'fyear_markjp DESC')
  end
end