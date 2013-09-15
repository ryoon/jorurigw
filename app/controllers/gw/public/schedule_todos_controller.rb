class Gw::Public::ScheduleTodosController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
    return redirect_to(request.env['PATH_INFO']) if params[:reset]
  end

  def init_params
    @params_set = Gw::ScheduleTodo.params_set(params)
    @js = %w(/_common/js/yui/build/animation/animation-min.js /_common/js/popup_calendar/popup_calendar.js /_common/js/yui/build/calendar/calendar.js /_common/js/dateformat.js)
    @css = %w(/_common/themes/gw/css/schedule.css /_common/themes/gw/css/todo.css)
    @group_selected = "schedule_todos"
    @sp_mode = :todo
    @myuid = Site.user.id
    @mygid = Site.user_group.id
    x = System::CustomGroup.get_my_view( {:is_default=>1,:first=>1})
    if !x.blank?
      @cgid = x.id
    end
  end

  def index
    init_params
    item = Gw::ScheduleTodo.new
    item.page  params[:page], params[:limit]
    cond = "(gw_schedule_users.uid = #{Site.user.id} or gw_schedules.creator_uid = #{Site.user.id})"
    cond += case params[:s_finished]
    when "2" # 完了
      ' and coalesce(is_finished, 0) = 1'
    when "3" # 両方
      ''
    else # 未完了
      ' and coalesce(is_finished, 0) != 1'
    end

    qsa = %w(s_finished)
    @qs = qsa.delete_if{|x| nz(params[x],'')==''}.collect{|x| %Q(#{x}=#{params[x]})}.join('&')
    @sort_keys = CGI.unescape(nz(params[:sort_keys], ''))

    indefinite_flg = false
    sk = @sort_keys
    if /^title (.+)$/ =~ sk

      _sk = sk.split(nil)
      sk =  'CAST(' + 'gw_schedules.' + _sk[0] + ' as char) ' + _sk[1] # 50音順

    elsif  /^ed_at (.+)$/ =~ sk
      if /desc$/ =~ sk
        indefinite_order = 'desc'
      else
        indefinite_order = 'asc'
      end
      indefinite_flg = true
      sk = "gw_schedule_todos.todo_ed_at_indefinite #{indefinite_order}, gw_schedules." + sk
    elsif !sk.blank?
      sk = 'gw_schedule_todos.' + sk
    end
    order = Gw.join([sk, 'is_finished', "#{indefinite_flg ? '' : 'gw_schedule_todos.todo_ed_at_indefinite desc'}", "#{Gw.order_last_null 'gw_schedule_todos.ed_at'}"], ',')

    @items = item.find(:all, :conditions => cond, :order => order, :include => {:schedule => [:schedule_users]})
  end

  def show
    init_params
    item = Gw::ScheduleTodo.new
    @item = item.find(params[:id])
  end

  def finish
    init_params
    @item = Gw::ScheduleTodo.find(params[:id])

    @is_gw_admin = Gw.is_admin_admin?
    user_exist_check = Gw::ScheduleUser.user_exist_check(@item.schedule_id, Site.user.id)

    if params.key?(:link) && params[:link] == 'show_one'
      redirect = "/gw/schedules/#{@item.schedule.id}/show_one"
    else
      redirect = "/gw/schedule_todos#{@params_set}"
    end

    act = nz(@item.is_finished, 0) != 1

    if nz(@item.schedule.todo, 0).to_i == 0 || (user_exist_check != true && @is_gw_admin != true && @item.schedule.creator_uid != Site.user.id )
      flash[:notice] = "Todoを#{act ? '完了する' : '未完了に戻す'}処理に失敗しました。権限がありません。"
      redirect_to redirect
      return
    end

    item = {}
    item[:finished_at] = Time.now
    item[:finished_uid] = Site.user.id
    item[:finished_gid] = Site.user_group.id
    item[:is_finished] = act ? 1 : 0

    @item.attributes = item
    _update @item, :success_redirect_uri => redirect, :notice => "Todoを#{act ? '完了する' : '未完了に戻す'}処理に成功しました"
  end

  def edit_user_property_schedule
    redirect_url = params[:url].to_s

    key = 'todos'
    hu = nz(Gw::Model::UserProperty.get(key.singularize), {})
    hu[key] = {} if hu[key].nil?
    hu_update = hu[key]
    is_todos_display = Gw::UserProperty.is_todos_display?
    if is_todos_display == true
      hu_update['todos_display_schedule'] = '0'
    else
      hu_update['todos_display_schedule'] = '1'
    end

    options = {}
    ret = Gw::Model::UserProperty.save(key.singularize, hu, options)
    if ret == true
      flash_notice('Todo表示設定', true)
      redirect_to redirect_url
    else
      flash_notice('Todo表示設定', false)
      redirect_to redirect_url
    end
  end

  def shift_todo
    @is_gw_admin = Gw.is_admin_admin?
    return authentication_error(403) unless @is_gw_admin == true
    todos = Gw::Todo.new.find(:all, :order => 'created_at')

    todos.each do |todo|

      todo_st_at_id = '2'
      todo_ed_at_id = '1'
      todo_repeat_time_id = '0'
      user = nil
      group = nil
      users_json = nil
      uname = nil
      created_at = todo.created_at.strftime("%Y-%m-%d %H:%M")

      if todo.is_finished.blank? || todo.is_finished == 0
        is_finished = 0
      else
        is_finished = 1
      end

      if todo.ed_at.blank?
        st_minute = todo.created_at.min
        st_minute = format("%02d", (st_minute / 5) * 5)
        st_at = todo.created_at.strftime("%Y-%m-%d %H:#{st_minute}")
      elsif todo.created_at < todo.ed_at
        if (todo.ed_at - todo.created_at) > 86400 * 364
          ed_day = Date.new(todo.ed_at.year, todo.ed_at.month, todo.ed_at.day)
          st_day = ed_day - 364
          st_at = "#{st_day.year}-#{st_day.month}-#{st_day.day} 00:00"
        else
          st_minute = todo.created_at.min
          st_minute = format("%02d", (st_minute / 5) * 5)
          st_at = todo.created_at.strftime("%Y-%m-%d %H:#{st_minute}")
        end
      else
        st_minute = todo.ed_at.min
        st_minute = format("%02d", (st_minute / 5) * 5)
        st_at = todo.ed_at.strftime("%Y-%m-%d %H:#{st_minute}")
      end

      if todo.ed_at.blank?
        ed_at = st_at
        todo_ed_at_id = '2'
      else
        ed_minute = todo.ed_at.min
        ed_minute = format("%02d", (ed_minute / 5) * 5)
        ed_at = todo.ed_at.strftime("%Y-%m-%d %H:#{ed_minute}")
        todo_ed_at_id = '1'
      end

      unless todo.uid.blank?
        user = System::User.find_by_id(todo.uid)
        unless user.user_groups.blank?
          group = user.user_groups[0].group
        end
        unless user.blank?
          users_json = "[[\"1\", \"#{user.id}\", \"#{user.display_name}\"]]"
          uname = user.display_name
        end
      end

      hash = {}
      hash[:prop_id] = ''
      hash[:s_genre] = ''
      hash[:action] = 'create'
      hash[:prop_id] = ''
      hash[:prop_id] = ''
      hash[:init] = {:prop_name => '', :schedule_props_json => '', :uname => uname, :schedule_users_json => '',
      :repeat_mode => '1', :ucls => '1', :uid => '4377', :public_groups_json => ''}
      hash[:item] = {
        :check_30_over => '',
        :schedule_props_json => '[]',
        :schedule_users_json => users_json,
        :form_kind_id => '2',
        :to_go => '',
        :title_category_id => '',
        :created_at => created_at,
        :title => todo.title,
        :todo_st_at_id => todo_st_at_id,
        :guide_ed_at => '0' ,
        :guide_state => '0' ,
        :memo => todo.body,
        :todo_repeat_time_id => todo_repeat_time_id,
        :todo_ed_at_id => todo_ed_at_id,
        :event_word => '' ,
        :participant_nums_inner =>  '',
        :inquire_to =>  '',
        :creator_uid => todo.uid,
        :is_public => '1',
        :owner_uid => todo.uid,
        :ed_at => "#{ed_at}",
        :place => '',
        :allday => '',
        :participant_nums_outer => '',
        :schedule_props => {:prop_type_id => 'other:other' },
        :st_at => "#{st_at}"
      }
      @item = Gw::Schedule.new

      unless users_json.blank?
        unless Gw::ScheduleRepeat.save_with_rels_concerning_repeat @item, hash, :create
          dump @item.errors.full_messages
          dump "#{todo.id}　#{todo.title}"
        else
          if !user.blank? && !group.blank?
            schedule = Gw::Schedule.find_by_id(@item.id)
            unless schedule.blank?
              schedule.updater_uid = user.id
              schedule.updater_ucode = user.code
              schedule.updater_uname = user.name
              schedule.updater_gid = group.id
              schedule.updater_gcode = group.code
              schedule.updater_gname = group.name
              schedule.save(false)
            end
          end
          re = Gw::ScheduleTodo.new.find(:first, :conditions => "schedule_id = #{@item.id}")
          re.is_finished = is_finished
          re.todo_id = todo.id
          re.save(false)
        end
      end
    end
    flash[:notice] = "Todoの移行を完了しました。"
    redirect_to "/gw/schedule_todos/"

  end

end
