class Gw::Public::PrefOnlyDirectorsController < ApplicationController

  def initialize_scaffold
    return redirect_to(request.env['PATH_INFO']) if params[:reset]
  end

  def index
    init_params

    item = Gw::PrefDirector.new #.readable
    item.and 'sql', "deleted_at IS NULL"
    item.order  params[:id], @sort_keys
    @items = item.find(:all)

    item = Gw::PrefDirector.new #.readable
    dept    =  "parent_g_code"
    g_order = "parent_g_order"
    @item_links  = item.find(:all ,:group=>dept , :order=>g_order)
  end

  def state_change
    @item = Gw::PrefDirector.find_by_uid(params[:id])
    old_state = params[:p_state]
    if old_state == "on"
      new_state = "off"
    elsif  old_state == "off"
      new_state = "on"
    end
    @item.state = new_state
    @item.save(false)
    @set = Gw::PrefExecutive.find_by_uid(params[:id])
    unless @set.blank?
      @set.state = new_state
      @set.save(false)
    end
    location  = Gw.chop_with(Site.current_node.public_uri,'/')
    location += "##{params[:locate]}" unless params[:locate].blank?
    return redirect_to(location)
  end

  def init_params
    @role_developer  = Gw::PrefDirector.is_dev?
    @role_admin      = Gw::PrefDirector.is_admin?
    @u_role = @role_developer || @role_admin

    @sort_keys = nz(params[:sort_keys], 'parent_g_order, u_order')
    @css = %w(/_common/themes/gw/css/schedule_assembly.css)

    @sp_mode = :zaichou_assembly

    @users = Gw::Model::Schedule.get_users(params)
    @user   = @users[0]
    @uid    = @user.id if !@user.blank?
    @uid = nz(params[:uid], Site.user.id) if @uid.blank?
    @myuid = Site.user.id
    @gid = nz(params[:gid], @user.groups[0].id) rescue Site.user_group.id
    @mygid = Site.user_group.id

    if params[:cgid].blank? && @gid != 'me'
      x = System::CustomGroup.get_my_view( {:is_default=>1,:first=>1})
      if !x.blank?
        @cgid = x.id
      end
    else
      @cgid = params[:cgid]
    end

    @first_custom_group = System::CustomGroup.get_my_view( {:sort_prefix => Site.user.code,:first=>1})

    @ucode = Site.user.code
    @gcode = Site.user_group.code

    @state_user_or_group = params[:cgid].blank? ? ( params[:gid].blank? ? :user : :group ) : :custom_group

    @group_selected = ( params[:cgid].blank? ? '' : 'custom_group_'+params[:cgid] )

    a_qs = []
    a_qs.push "uid=#{params[:uid]}" unless params[:uid].nil?
    a_qs.push "gid=#{params[:gid]}" unless params[:gid].nil? && !params[:cgid].nil?
    a_qs.push "cgid=#{params[:cgid]}" unless params[:cgid].nil? && !params[:gid].nil?
    a_qs.push "todo=#{params[:todo]}" unless params[:todo].nil?
    @schedule_move_qs = a_qs.join('&amp;')

    @is_gw_admin = Gw.is_admin_admin?
    @is_pref_admin = Gw::Schedule.is_schedule_pref_admin?

    @is_kauser = @kucode == @ucode ? true : false

    unless params[:cgid].blank?
      @custom_group = System::CustomGroup.find(:first, :conditions=>"id=#{params[:cgid]}")
      if !@custom_group.blank?
        Page.title = @custom_group.name
      end
    end

    @up_schedules = nz(Gw::Model::UserProperty.get('schedules'.singularize), {})

    @schedule_settings = Gw::Model::Schedule.get_settings 'schedules', {}

  end

end
