class Gw::Public::SchedulePropsController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
    return redirect_to(request.env['PATH_INFO']) if params[:reset]
  end

  def init_params
    @genre = params[:s_genre]
    @genre = Gw.trim(nz(@genre)).downcase
    genre = @genre

    a_genres = Gw::ScheduleProp.get_genres
    @cls = params[:cls]

    case params['action']
    when 'getajax'

    else
      raise Gw::ApplicationError, "指定がおかしいです(#{genre})" if !genre.blank? && a_genres.assoc(genre).nil?
    end
    @title = genre.blank? ? '施設' : a_genres.assoc(genre)[1]
    @s_genre = genre == '' ? '' : "?s_genre=#{genre}"
    @piece_head_title = '施設スケジュール'
    @index_order = 'extra_flag, sort_no, gid, name'
    @js= ['/_common/js/gw_schedules.js'] +
      %w(gw_schedules popup_calendar/popup_calendar dateformat).collect{|x| "/_common/js/#{x}.js"} +
      %w(yahoo dom event container menu animation calendar).collect{|x| "/_common/js/yui/build/#{x}/#{x}-min.js"}
    @css = %w(/_common/js/yui/build/menu/assets/menu.css /_common/themes/gw/css/schedule.css)
    @uid = Gw::Model::Schedule.get_uids(params)[0]
    @gid = nz(params[:gid], Gw::Model::Schedule.get_user(@uid).groups[0].id) rescue Site.user_group.id
    @mygid = Site.user_group.id
    @state_user_or_group = params[:gid].blank? ? :user : :group
    @sp_mode = :prop

    a_qs = []
    a_qs.push "uid=#{params[:uid]}" unless params[:uid].nil?
    a_qs.push "gid=#{params[:gid]}" unless params[:gid].nil?
    a_qs.push "cls=#{@cls}"
    a_qs.push "s_genre=#{@genre}"
    @schedule_move_qs = a_qs.join('&amp;')

   if !params[:prop_id].blank?
     prop_gid = Gw::Model::Schedule.get_prop_model(params).find(:first, :conditions =>  ["id= ? ", params[:prop_id]])
     @prop_gid = prop_gid.blank? ? nil : prop_gid.gid
   end
    @pgid_flg = false
    @pgid_flg = true if @prop_gid.to_i != @gid.to_i
    @up_schedules = nz(Gw::Model::UserProperty.get('schedules'.singularize), {})

    @is_gw_admin = Gw.is_admin_admin?

    @schedule_settings = Gw::Model::Schedule.get_settings 'schedules', {}
    @s_other_admin_gid = nz(params[:s_other_admin_gid], "0").to_i
  end

  def index
    init_params
    @line_box = 1
    item = Gw::ScheduleProp.new
    cond_a = [item.search_where(params)]
    cond_a.push '(now() <= gw_schedules.ed_at)'
    cond = Gw.join(cond_a, ' and ')

    @items = item.find(:all, :select=>'gw_schedule_props.*, gw_schedules.st_at, gw_schedules.ed_at',
      :joins=> <<"EOL",
left join gw_schedules on gw_schedule_props.schedule_id = gw_schedules.id
EOL
      :conditions=>cond)
    @items = @items.select{|x| x.prop.extra_flag.nil? ? Site.user_group.code == x.prop.gid : extras.key?(x.prop.extra_flag) }
  end

  def show
    init_params
    @line_box = 1
    @st_date = Gw.date8_to_date params[:id]
  end

  def show_week
    init_params
    @line_box = 1
    kd = params['s_date']
    @st_date = kd =~ /[0-9]{8}/ ? Date.strptime(kd, '%Y%m%d') : Date.today
  end

  def show_month
    init_params
    @line_box = 1
    kd = params['s_date']
    @st_date = kd =~ /[0-9]{8}/ ? Date.strptime(kd, '%Y%m%d') : Date.today
  end


  def getajax
    @item = Gw::ScheduleProp.getajax params
    _show @item
  end

end
