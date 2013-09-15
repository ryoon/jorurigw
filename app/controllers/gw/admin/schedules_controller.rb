class Gw::Admin::SchedulesController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
    return redirect_to(request.env['PATH_INFO']) if params[:reset]
  end

  def init_params
    @title = 'ユーザ'
    @piece_head_title = 'スケジュール'
    @js = %w(/_common/js/yui/build/animation/animation-min.js /_common/js/popup_calendar/popup_calendar.js /_common/js/yui/build/calendar/calendar.js /_common/js/dateformat.js)
    @css = %w(/_common/themes/gw/css/schedule.css)

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
    @sp_mode = :schedule

    @group_selected = ( params[:cgid].blank? ? '' : 'custom_group_'+params[:cgid] )

    a_qs = []
    a_qs.push "uid=#{params[:uid]}" unless params[:uid].nil?
    a_qs.push "gid=#{params[:gid]}" unless params[:gid].nil? && !params[:cgid].nil?
    a_qs.push "cgid=#{params[:cgid]}" unless params[:cgid].nil? && !params[:gid].nil?
    a_qs.push "todo=#{params[:todo]}" unless params[:todo].nil?
    @schedule_move_qs = a_qs.join('&amp;')

    @is_gw_admin = Gw.is_admin_admin?

    @is_kauser = @kucode == @ucode ? true : false

    unless params[:cgid].blank?
      @custom_group = System::CustomGroup.find(:first, :conditions=>"id=#{params[:cgid]}")
      if !@custom_group.blank?
        Page.title = @custom_group.name
      end
    end

    @up_schedules = nz(Gw::Model::UserProperty.get('schedules'.singularize), {})

    @schedule_settings = Gw::Model::Schedule.get_settings 'schedules', {}

    @topdate = nz(params[:topdate]||Time.now.strftime('%Y%m%d'))
    @dis = nz(params[:dis],'week')
  end

  def index
    init_params
    @line_box = 1
    @st_date = Gw.date8_to_date params['s_date']
  end

  def show
    init_params
    @line_box = 1
    @st_date = Gw.date8_to_date params[:id]
  end

  def new
    init_params

    @item = Gw::Schedule.new({:is_public=>1})
    @system_role_classes = Gw.yaml_to_array_for_select('system_role_classes')
    @js += %w(/_common/modules/ips/ips.js)
    @css += %w(/_common/modules/ips/ips.css)
    if request.mobile?
      unless flash[:mail_to].blank?
        @users_json = set_participants(flash[:mail_to]).to_json
      end
    end
  end

  def quote
    @quote = true
    __edit
  end

  def edit
    __edit
  end

  def __edit
    init_params

    @item = Gw::Schedule.new.find(params[:id])
    auth_level = @item.get_edit_delete_level(auth = {:is_gw_admin => @is_gw_admin})

    return authentication_error(403) if auth_level[:edit_level] != 1 && !@quote
    users = []
    @item.schedule_users.each do |user|
      _name = ''
      if user.class_id == 1
        _name = user.user.display_name if !user.user.blank? && user.user.state == 'enabled'
      else
        group = System::Group.find(:first,  :conditions=>"id=#{user.uid}")
        _name = group.name if !group.blank? && group.state == 'enabled'
      end
      unless _name.blank?
        name = Gw.trim(_name)
        users.push [user.class_id, user.uid, name]
      end
    end

    public_groups = Array.new
    @item.public_roles.each do |public_role|
      name = Gw.trim(public_role.class_id == 2 ? public_role.group.name :
        public_role.user.name)
      public_groups.push ["", public_role.uid, name]
    end

    props = Array.new
    props_items = Array.new

    if params[:sh] == 'sh'
      props_items = @item.get_parent_props_items
    else
      props_items = @item.schedule_props
    end

    props_items.each do |prop|
      title = prop.prop_type.sub(/^Gw::Prop/,'').downcase
      if !prop.prop.blank?
        if title == "other"
          gname = prop.prop.gname
          gid = prop.prop.gid
          kamei = !gname.blank? ? "(" + System::Group.find(gid).code.to_s + ")" : ""
          props.push [title, prop.prop_id, kamei + prop.prop.name]
        else
          if prop.prop.delete_state == 0 && prop.prop.reserved_state == 1
            props.push [title, prop.prop_id, prop.prop.name]
          end
        end
      end
    end
    @users_json = users.to_json
    if request.mobile?
      unless flash[:mail_to].blank?
        @users_json = set_participants(flash[:mail_to]).to_json
      end
    end
    @props_json = props.to_json
    @public_groups_json = public_groups.to_json
  end

  def show_one
    init_params

    @line_box = 1
    if !params[:m].blank? && (params[:m] == "new" || params[:m] == "edit")
      item = Gw::Schedule.find(params[:id])
      @items = Gw::Schedule.find(:all, :conditions=>"schedule_parent_id = #{item.schedule_parent_id}")
    else
      @items = Gw::Schedule.find(:all, :conditions=>"id = #{params[:id]}")
    end

    @items.each do |item|
      @auth_level = item.get_edit_delete_level(auth = {:is_gw_admin => @is_gw_admin})
    end
  end

  def show_month
    init_params
    @line_box = 1
    kd = params['s_date']
    @st_date = kd =~ /[0-9]{8}/ ? Date.strptime(kd, '%Y%m%d') : Date.today
  end

  def create
    init_params
    if request.mobile?
      _params = set_mobile_params params
      _params = reject_no_necessary_params _params
    else
      _params = reject_no_necessary_params params
    end
    @item = Gw::Schedule.new()
    if Gw::ScheduleRepeat.save_with_rels_concerning_repeat(@item, _params, :create)
      flash_notice '予定の登録', true
      redirect_url = @item.schedule_parent_id.blank? ? "/gw/schedules/#{@item.id}/show_one" : "/gw/schedules/#{@item.id}/show_one?m=new"
      if request.mobile?
        if @item.schedule_parent_id.blank?
          redirect_url += "?gid=#{params[:gid]}&cgid=#{params[:cgid]}&uid=#{params[:uid]}&dis=#{params[:dis]}"
        else
          redirect_url += "&gid=#{params[:gid]}&cgid=#{params[:cgid]}&uid=#{params[:uid]}&dis=#{params[:dis]}"
        end
      end
      redirect_to redirect_url
    else
      respond_to do |format|
        format.html { render :action => "new" }
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    init_params

    if request.mobile?
      _params = set_mobile_params params
      _params = reject_no_necessary_params _params
      @item = Gw::Schedule.find(params[:id])
    else
      _params = reject_no_necessary_params params
      @item = Gw::Schedule.find(params[:id])
      _params = reject_no_necessary_params params
    end

    if !@item.schedule_parent_id.blank?
      item_schedule_parents = Gw::Schedule.find(:all, :conditions=>"id != #{params[:id]} and schedule_parent_id = #{@item.schedule_parent_id}")
      item_schedule_parents.each{ |item_schedule_parent|
        item_schedule_parent.schedule_parent_id = nil
        item_schedule_parent.save
      }
    end

    if Gw::ScheduleRepeat.save_with_rels_concerning_repeat(@item, _params, :update)
      flash[:notice] = '予定の編集に成功しました。'
      redirect_url = @item.schedule_parent_id.blank? ? "/gw/schedules/#{@item.id}/show_one" : "/gw/schedules/#{@item.id}/show_one?m=edit"
      if request.mobile?
        if @item.schedule_parent_id.blank?
          redirect_url += "?gid=#{params[:gid]}&cgid=#{params[:cgid]}&uid=#{params[:uid]}&dis=#{params[:dis]}"
        else
          redirect_url += "&gid=#{params[:gid]}&cgid=#{params[:cgid]}&uid=#{params[:uid]}&dis=#{params[:dis]}"
        end
      end
      redirect_to redirect_url
    else
      respond_to do |format|
        format.html { render :action => "edit" }
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    init_params
    @item = Gw::Schedule.find(params[:id])
    auth_level = @item.get_edit_delete_level(auth = {:is_gw_admin => @is_gw_admin})
    return authentication_error(403) if auth_level[:delete_level] != 1

    st = @item.st_at.strftime("%Y%m%d")
    othlinkflg = false
    beflg = false

    @item.schedule_props.each do |pro|
      if pro.prop_type == 'Gw::PropOther'
        othlinkflg = true
        beflg = true if @gid.to_i != pro.prop.gid.to_i
      end
    end

    if othlinkflg
      location = "/gw/schedule_props/show_week?s_date=#{st}&cls=other&s_genre=other"
      location += "&be=other" if beflg
    else
      location = Gw.chop_with("#{Site.current_node.public_uri}",'/')
    end

    _destroy(@item,:success_redirect_uri=>location)
  end

  def destroy_repeat
    init_params
    item = Gw::Schedule.find(params[:id])
    auth_level = item.get_edit_delete_level(auth = {:is_gw_admin => @is_gw_admin})
    return authentication_error(403) if auth_level[:delete_level] != 1

    st = item.st_at.strftime("%Y%m%d")
    otherlinkflg = false;

    item.schedule_props.each do |pro|
      if pro.prop_type == 'Gw::PropOther'
        otherlinkflg = true
      end
    end

    schedule_repeat_id = item.repeat.id

    repeat_items = Gw::Schedule.new.find(:all, :conditions=>"schedule_repeat_id=#{schedule_repeat_id}")
    repeat_items.each { |repeat_item|
        repeat_item.destroy if !repeat_item.is_actual?
    }

    if otherlinkflg
      redirect_url = "/gw/schedule_props/show_week?s_date=#{st}&cls=other&s_genre=other"
    else
      redirect_url = "/gw/schedules/show_month"
    end

    flash_notice '繰り返し一括削除', true
    redirect_to redirect_url
  end

  def setting
    init_params
  end

  def setting_system
    init_params
  end

  def setting_holidays
    init_params
  end

  def setting_gw_link
    init_params
    @item = Gw::SystemProperty.find(:first, :conditions=> {:name => "gw_link"})
  end

  def edit_gw_link
    edit_system_setting "gw_link"
  end

  def edit_system_setting(key)
    init_params
    @item = Gw::SystemProperty.find(:first, :conditions=> {:name => "gw_link"})
    respond_to do |format|
      format.html {
        render :action => "setting_#{key}"
      }
      format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
    end
  end

  def setting_ind
    init_params
  end

  def setting_ind_schedules
    setting_ind_core 'schedules'
  end

  def setting_ind_ssos
    setting_ind_core 'ssos'
  end

  def setting_ind_mobiles
    setting_ind_core 'mobiles'
  end

  def setting_ind_core(key)
    init_params
    @item = Gw::Model::Schedule.get_settings key
  end

  def edit_ind_schedules
    edit_ind 'schedules'
  end

  def edit_ind_ssos
    edit_ind 'ssos'
  end

  def edit_ind_mobiles
    edit_ind 'mobiles'
  end

  def edit_ind(key)
    init_params
    options = {}
    raise ArgumentError, '呼び出しパラメータが不正です。' if %w(schedules ssos mobiles).index(key).nil?
    options[:nodefault] = 1 if !%w(ssos).index(key).nil?
    edit_ind_core key, options
  end

  def edit_ind_core(key, options={})
    _params = params[:item]
    hu = nz(Gw::Model::UserProperty.get(key.singularize), {})
    trans = Gw.yaml_to_array_for_select("gw_#{key}_settings_ind", :rev=>1)
    trans_raw = Gw::NameValue.get('yaml', nil, "gw_#{key}_settings_ind")
    default = Gw::NameValue.get('yaml', nil, "gw_#{key}_settings_system_default") if options[:nodefault].nil?
    cols = trans.collect{|x| x[0]}
    hu[key] = {} if hu[key].nil?
    hu_update = hu[key]
    if key == 'ssos'
      hu[key]['pref_soumu'] = {} if hu[key]['pref_soumu'].nil?
      hu_update = hu[key]['pref_soumu']
    end
    password_fields = trans_raw['_password_fields'].blank? ? [] : trans_raw['_password_fields'].split(':')
    cols.each do |x|
      hu_update[x] = _params[x]
      hu_update[x] = hu_update[x].encrypt if !password_fields.index(x).nil? && !hu_update[x].blank?
    end
    ret = Gw::Model::UserProperty.save(key.singularize, hu, options)
    if key=='mobiles'
      case ret
      when 0
        flash[:notice] = '転送設定編集処理に成功しました。'
        redirect_to "/gw/memo_settings"
      when 2
        flash[:notice] = '転送設定編集処理に成功しました。アドレスフォーマットが独自フォーマットになっているため、転送されない場合があります。'
        redirect_to "/gw/memo_settings"
      else
        respond_to do |format|
          format.html {
            hu_update['errors'] = ret
            hu_update.merge!(default){|k, self_val, other_val| self_val} if options[:nodefault].nil?
            @item = hu[key]
            render :action => "setting_ind_#{key}"
          }
          format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
        end
      end
    else
      if ret == true
        if key=='ssos'
          flash_notice('シングルサインオン設定編集処理', true)
          redirect_to "/"
        else
          flash_notice('スケジューラ設定編集処理', true)
          redirect_to "/gw/schedules/setting_ind"
        end
      else
        respond_to do |format|
          format.html {
            hu_update['errors'] = ret
            hu_update.merge!(default){|k, self_val, other_val| self_val} if options[:nodefault].nil?
            @item = hu[key]
            render :action => "setting_ind_#{key}"
          }
          format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  def search
    init_params
    @group_selected = 'all_group'
    @st_date = Gw.date8_to_date params['s_date']
  end

private
  def set_mobile_params(params_i)
    params_o = params_i.dup
    if params_o[:item][:allday] != "1"
      params_o[:item].delete "allday_radio_id"
    end
    st_at_str = %Q(#{params_o[:item]['st_at(1i)']}-#{params_o[:item]['st_at(2i)']}-#{params_o[:item]['st_at(3i)']} #{params_o[:item]['st_at(4i)']}:#{params_o[:item]['st_at(5i)']})
    params_o[:item].delete "st_at(1i)"
    params_o[:item].delete "st_at(2i)"
    params_o[:item].delete "st_at(3i)"
    params_o[:item].delete "st_at(4i)"
    params_o[:item].delete "st_at(5i)"
    params_o[:item][:st_at]= st_at_str
    ed_at_str = %Q(#{params_o[:item]['ed_at(1i)']}-#{params_o[:item]['ed_at(2i)']}-#{params_o[:item]['ed_at(3i)']} #{params_o[:item]['ed_at(4i)']}:#{params_o[:item]['ed_at(5i)']})
    params_o[:item].delete "ed_at(1i)"
    params_o[:item].delete "ed_at(2i)"
    params_o[:item].delete "ed_at(3i)"
    params_o[:item].delete "ed_at(4i)"
    params_o[:item].delete "ed_at(5i)"
    params_o[:item][:ed_at]= ed_at_str
    users_json = []
    if params_o[:item][:schedule_users].blank?
      #
    else
      params_o[:item][:schedule_users].each do |u|
        if u[1].to_i != 0
          user_name = System::User.find_by_id(u[1])
          users_json << ["1",u[1],"#{user_name.name}"]
        end
      end
      params_o[:item][:schedule_users_json] = users_json.to_json
    end
    public_groups_json = []
    if params_o[:item][:public_groups].blank?
      #
    else
      params_o[:item][:public_groups].each do |g|
        if g[1].to_i != 0
          group_name = System::Group.find_by_id(g[1])
          public_groups_json << ["1",g[1],"#{group_name.name}"]
        end
      end
      params_o[:item][:public_groups_json] = public_groups_json.to_json
      params_o[:init][:public_groups_json] = public_groups_json.to_json
    end
    params_o[:item][:public_groups][:gid] = Site.user_group.parent_id
    dump params_o
    return params_o
  end

  def set_participants(member_str)
    users = member_str.split(',')
    users_json = []
    unless users.blank?
      users.each do |u|
        user_name = System::User.find_by_id(u)
        users_json << [1,u,"#{user_name.name}"]
      end
    end
    return users_json
  end

  def reject_no_necessary_params(params_i)
    params_o = params_i.dup
    params_o[:item].reject!{|k,v| /^(owner_udisplayname)$/ =~ k}

    case params_o[:init][:repeat_mode]
    when "1"
      params_o[:item].reject!{|k,v| /^(repeat_.+)$/ =~ k}
    when "2"
      params_o[:item].delete :st_at
      params_o[:item].delete :ed_at
      params_o[:item][:repeat_weekday_ids] = Gw.checkbox_to_string(params_o[:item][:repeat_weekday_ids])
      params_o[:item][:allday] = params_o[:item][:repeat_allday]
      params_o[:item].delete :repeat_allday
    else
      raise Gw::ApplicationError, "指定がおかしいです(repeat_mode=#{params_o[:init][:repeat_mode]})"
    end

    params_o[:item].reject!{|k,v| /\(\di\)$/ =~ k}
    params_o
  end

  def is_creator(item)
    return true if @is_gw_admin

    stat = 0
    prop_type = ""
    gid = 0
    prop_id = 0
    flg = false
    item.schedule_props.each do |prop|
      stat = prop.prop_stat
      prop_type = prop.prop_type
      gid = prop.prop.gid unless prop.prop.blank?
      prop_id = prop.prop.id
    end

    stat = nz(stat, 0).to_i

    return true if Gw::PropOtherRole.is_admin?(prop_id, @mygid) && prop_type == "Gw::PropOther"
    return true if item.creator_uid == @myuid && stat.blank?
    return true if item.creator_uid == @myuid && stat == 0
    return false if !stat.blank? && stat > 0

    if prop_type.blank?
      uids = item.schedule_users.select{|x|x.class_id==1}.collect{|x| x.uid}
      flg = !uids.index(@myuid).nil?
    end

    if flg
      return true
    else
      return false unless item.creator_gid == @mygid
    end

    return false
  end


end
