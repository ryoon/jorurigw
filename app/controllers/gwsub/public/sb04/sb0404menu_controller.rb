class Gwsub::Public::Sb04::Sb0404menuController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
    return redirect_to(request.env['PATH_INFO']) if params[:reset]
  end

  def index
    init_params
    current_id = Site.current_node.id
    parent_id   = Site.current_node.parent_id

    item = Cms::Node.new #.readable
    item.page   params[:page], nz(params[:limit], 30)
    item.order  params[:id], @sort_keys
    conditions = "state='public' and parent_id = #{parent_id} and id != #{current_id} "
    @items = item.find(:all, :conditions => conditions )
    _index @items
  end

  def init_params
    # ユーザー権限設定
    @role_developer  = Gwsub::Sb04stafflist.is_dev?(Site.user.id)
    @role_admin      = Gwsub::Sb04stafflist.is_admin?(Site.user.id)
    @u_role = @role_developer || @role_admin

    # 電子職員録 主管課権限設定
    @role_sb04_dev  = Gwsub::Sb04stafflistviewMaster.is_sb04_dev?

    @menu_header3 = 'sb0404menu'
    @menu_title3  = 'コード管理'
    search_condition
    sortkeys_setting
    @css = %w(/_common/themes/gw/css/gwsub.css)
    @l1_current = '05'
    @l2_current = '01'
    @l3_current = '01'
  end
  def search_condition
  end
  def sortkeys_setting
    @sort_keys = nz(params[:sort_keys], 'title ASC')
  end
end
