class Gwsub::Public::Sb04::Sb04helpsController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
    return redirect_to(request.env['PATH_INFO']) if params[:reset]
  end

  def index
    init_params
    item = Gwsub::Sb04help.new #.readable
    item.search params
    item.page   params[:page], params[:limit]
    item.order  params[:id], @sort_keys
    @items = item.find(:all)
    _index @items
  end

  def show
    init_params
    @item = Gwsub::Sb04help.find(params[:id])
  end

  def edit
    init_params
    @item = Gwsub::Sb04help.find(params[:id]) #.readable
  end
  def update
    init_params
    @item = Gwsub::Sb04help.new.find(params[:id])
    @item.attributes = params[:item]
    location = Gw.chop_with("#{Site.current_node.public_uri}",'/')
    options = {
      :success_redirect_uri=>location}
    _update(@item,options)
  end

  def new
    init_params
    @l2_current = '02'
    @item = Gwsub::Sb04help.new
    @item.categories  = 1
  end
  def create
    init_params
    @l2_current = '02'
    @item = Gwsub::Sb04help.new(params[:item])
    location = Gw.chop_with("#{Site.current_node.public_uri}",'/')
    options = {
      :success_redirect_uri=>location}
    _create(@item,options)
  end

  def destroy
    init_params
    @item = Gwsub::Sb04help.find(params[:id])
    location = Gw.chop_with("#{Site.current_node.public_uri}",'/')
    options = {
      :success_redirect_uri=>location}
    _destroy(@item,options)
  end

  def init_params
    # ユーザー権限設定
    @role_developer  = Gwsub::Sb04stafflist.is_dev?(Site.user.id)
    @role_admin      = Gwsub::Sb04stafflist.is_admin?(Site.user.id)
    @u_role = @role_developer || @role_admin

    # 電子職員録 主管課権限設定
    @role_sb04_dev  = Gwsub::Sb04stafflistviewMaster.is_sb04_dev?

    @menu_header3 = 'sb04helps'
    @menu_title3  = 'ヘルプ'
    # 表示行数　設定
    @limits = nz(params[:limit],30)

    search_condition
    sortkeys_setting
    @css = %w(/_common/themes/gw/css/gwsub.css)
    @l1_current = '04'
    @l2_current = '01'

  end

  def search_condition
    params[:limit] = nz(params[:limit], @limits)

    qsa = [ 'limit','s_keyword'  ]
    @qs = qsa.delete_if{|x| nz(params[x],'')==''}.collect{|x| %Q(#{x}=#{params[x]})}.join('&')
  end
  def sortkeys_setting
    @sort_keys = nz(params[:sort_keys], 'title DESC')
  end

end
