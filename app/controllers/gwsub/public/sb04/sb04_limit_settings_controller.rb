class Gwsub::Public::Sb04::Sb04LimitSettingsController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold

  end

  def init_params
    @is_gw_admin = Gw.is_admin_admin? # GW全体の管理者
    @sp_mode = :schedule

    @erb_base = '/gw/public/prop_genre_common'
    @css = %w(/_common/themes/gw/css/gwsub.css)

    @role_developer  = Gwsub::Sb04stafflist.is_dev?(Site.user.id)
    @role_admin      = Gwsub::Sb04stafflist.is_admin?(Site.user.id)
    @u_role = @role_developer || @role_admin || @is_gw_admin

    @menu_header3 = 'sb04_admin_settings'
    @menu_title3  = '職員録 管理者設定'
    @l1_current = '07'
    
    @public_uri = Site.current_node.public_uri
  end

  def index
    init_params
    return authentication_error(403) unless @u_role == true
    @l2_current = '01'
    item = Gwsub::Sb04LimitSetting.new #.readable
    item.page   params[:page], params[:limit]
    @items = item.find(:all, :conditions => "type_name = 'stafflistview_limit' or type_name = 'divideduties_limit'", :order => "id")
  end

  def show
    init_params
    return authentication_error(403) unless @u_role == true
    @l2_current = '01'
    @item = Gwsub::Sb04LimitSetting.find(params[:id])
  end

  def edit
    init_params
    return authentication_error(403) unless @u_role == true
    @l2_current = '01'
    @item = Gwsub::Sb04LimitSetting.find(params[:id])
  end

  def update
    init_params
    return authentication_error(403) unless @u_role == true
    @item = Gwsub::Sb04LimitSetting.find(params[:id])
    @item.attributes = params[:item]

    if @item.valid?
      _update @item, :success_redirect_uri => "#{Site.current_node.public_uri}#{@item.id}", :notice => "主管課ユーザーの更新に成功しました。"
    else
      respond_to do |format|
        format.html { render :action => "edit" }
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
    end

  end

end
