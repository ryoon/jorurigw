class Gwboard::Public::ImagesController < ApplicationController
  include Gwboard::Controller::Scaffold
  include Gwboard::Controller::Authorize
  include Gwboard::Controller::Common

  def initialize_scaffold
    @css = ["/_common/themes/gw/css/gwbbs_standard.css"]
    params[:st] = '2' if params[:st].blank?
    @share_mode = params[:st]
    @sub_title = ''
    @sub_title = '所属用背景画像' if @share_mode == '0'
    @sub_title = '所属用アイコン' if @share_mode == '1'
    @sub_title = '背景画像' if @share_mode == '2'
    @sub_title = 'アイコン' if @share_mode == '3'
 end

  def set_admin_flag
    @is_sysadm = false
    @is_sysadm = System::Model::Role.get(1, Site.user.id ,'_admin', 'admin')
  end

  def index
    set_admin_flag
    item = Gwboard::Image.new
    item.and :share, @share_mode
    item.and :section_code , Site.user_group.code unless @is_sysadm if @share_mode < '2'
    item.page params[:page], params[:limit]
    @items = item.find(:all)
  end

  def new
    set_admin_flag
    item = Gwboard::Image
    @item = item.new({
      :state => 'public' ,
      :section_code => Site.user_group.code,
      :share => @share_mode
    })
  end

  def show
    set_admin_flag
    item = Gwboard::Image
    @item = item.new.find(params[:id])
    return error_auth unless @item
    return error_auth unless @item.section_code == Site.user_group.code unless @is_sysadm  if @item.share < 2
    @share_mode = @item.share.to_s
    @sub_title = ''
    @sub_title = '所属用背景画像' if @share_mode == '0'
    @sub_title = '所属用アイコン' if @share_mode == '1'
    @sub_title = '全庁用背景画像' if @share_mode == '2'
    @sub_title = '全庁用アイコン' if @share_mode == '3'

    _show @item
  end

  def create
    set_admin_flag
    item = Gwboard::Image
    @item = item.new(params[:item])
    @item.state = 'public'
    @item.section_code = Site.user_group.code unless @is_sysadm
    update_creater_editor   #Gwboard::Controller::Common

    group = Gwboard::Group.new
    group.and :state , 'enabled'
    group.and :code ,@item.section_code
    group = group.find(:first)
    @item.section_name = group.code + group.name if group
    _create @item
  end

  def update
    set_admin_flag
    item = Gwboard::Image
    @item = item.new.find(params[:id])
    @item.attributes = params[:item]
    @item.state = 'public'
    update_creater_editor   #Gwboard::Controller::Common

    group = Gwboard::Group.new
    group.and :state , 'enabled'
    group.and :code ,@item.section_code
    group = group.find(:first)
    @item.section_name = group.code + group.name if group
    @item._update = true
    _create @item
  end

  def destroy
    set_admin_flag
    item = Gwboard::Image
    @item = item.new.find(params[:id])
    _destroy @item
  end

end
