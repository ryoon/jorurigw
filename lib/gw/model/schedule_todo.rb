module Gw::Model::Schedule_todo

  def self.remind(uid = Site.user.id)
    item = Gw::ScheduleTodo.new
    d = Date.today
    setting = Gw::Model::Schedule.get_settings 'todos',{}
    cond = Gw::Model::Schedule_todo.remind_cond(d, uid, setting)

    return {} if setting['finish_todos_display'].to_i == 0 && setting['unfinish_todos_display_start'].to_i == 0 && setting['unfinish_todos_display_end'].to_i == 0
    items = item.find(:all, :order => 'gw_schedule_todos.ed_at', :include => {:schedule => [:schedule_users]},
      :conditions => cond)

    return items.collect{|x|
      delay = nz(Gw.datetimediff(Date.today, x.ed_at, :ignore_time=>1), -1)
      delay_s = delay >= 0 ? "last#{delay}" : 'delay'

      data_d = nil
      if !x.ed_at.blank? && nz(x.todo_ed_at_id, 0) == 1
        data_d = Time.local(x.ed_at.year, x.ed_at.month, x.ed_at.day, 0, 0, 0)
      elsif !x.ed_at.blank?
        data_d = Time.local(x.ed_at.year, x.ed_at.month, x.ed_at.day, 23, 59, 59)
      end

      {
        :date_str => x.ed_at.nil? ? '期限なし' : x.ed_at.strftime("%m/%d %H:%M"),
        :cls => 'TODO',
        :title => %Q(<a href="/gw/schedules/#{x.schedule_id}/show_one">#{x.schedule.title}</a>),
        :delay => x.ed_at.nil? ? false : Time.now > x.ed_at,
        :css_class => delay_s,
        :date_d => nz(data_d, Time.local(2030, 4, 1, 23, 59, 59)) # 期限なしは最上部とする。
    }}
  end

  def self.remind_cond(d, uid = nil, options={})
    ret = "gw_schedule_users.uid = #{uid} and gw_schedule_todos.ed_at is not null and  coalesce(gw_schedule_todos.todo_ed_at_id, 0) != 2"

    table = "gw_schedule_todos"

    if options['finish_todos_display'].blank? || options['unfinish_todos_display_start'].blank? || options['unfinish_todos_display_end'].blank?
      return ret
    end
    tmp = ''
    read_d = d - options['finish_todos_display'].to_i + 1
    if !options['finish_todos_display'].blank? && options['finish_todos_display'].to_i != 0
      tmp += " ( #{table}.is_finished = 1 and ( ( #{table}.ed_at >= '#{read_d.strftime('%Y-%m-%d 0:0:0')}' and #{table}.ed_at < '#{d.strftime('%Y-%m-%d 23:59:59')}' ) ) )"
    elsif options['finish_todos_display'].to_i == 0
      tmp += " ( coalesce(#{table}.is_finished, 0) != 1 ) "
    end

    tie = ''
    if options['finish_todos_display'].to_i == 0
      tie = " and " if tmp != ""
    else
      tie = " or " if tmp != ""
    end
    start_d = d - options['unfinish_todos_display_start'].to_i + 1
    end_d = d + options['unfinish_todos_display_end'].to_i
    if !options['unfinish_todos_display_start'].blank? && options['unfinish_todos_display_start'].to_i != 0 && !options['unfinish_todos_display_end'].blank? && options['unfinish_todos_display_end'].to_i != 0
      tmp += tie
      tmp += " coalesce(#{table}.is_finished, 0) != 1 and ( ( #{table}.ed_at >= '#{start_d.strftime('%Y-%m-%d 0:0:0')}'  and #{table}.ed_at < '#{end_d.strftime('%Y-%m-%d 0:0:0')}' ) ) "
    elsif options['unfinish_todos_display_start'].to_i != 0 && options['unfinish_todos_display_end'].to_i == 0
      tmp += tie
      tmp += " ( coalesce(#{table}.is_finished, 0) != 1 and ( ( #{table}.ed_at >= '#{start_d.strftime('%Y-%m-%d 0:0:0')}'  and #{table}.ed_at < '#{d.strftime('%Y-%m-%d 23:59:59')}' ) ) )"
    elsif options['unfinish_todos_display_start'].to_i == 0 && options['unfinish_todos_display_end'].to_i != 0
      tmp += tie
      tmp += " ( coalesce(#{table}.is_finished, 0) != 1 and ( ( #{table}.ed_at >= '#{d.strftime('%Y-%m-%d 0:0:0')}'  and #{table}.ed_at < '#{end_d.strftime('%Y-%m-%d 0:0:0')}' ) ) )"
    elsif options['unfinish_todos_display_start'].to_i == 0 && options['unfinish_todos_display_end'].to_i == 0
      tmp += " and " if tmp != ""
      tmp += " ( coalesce(#{table}.is_finished, 0) != 0 ) "
    end

    ret += " and  ( " + tmp + " ) " if (tmp != '')
    "(#{ret})"
  end
end
