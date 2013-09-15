module Gw::Model::MobileSchedule

  def self.create_user_prop_view(d1, d2, uid, params, options={})
    sp_mode = options[:sp_mode]
    items = sp_mode == :schedule ? Gw::Model::Schedule.select_my_data(d1, d2, uid, options) :
      sp_mode == :event ? Gw::Model::Schedule.select_event_data(d1, d2, uid, options) :
      Gw::Model::Schedule.select_prop_data(d1, d2, uid, params, options)
    return items
  end


  def self.create_user_prop_view_cache(d1, d2, uid, params, options={})
    c_key = "Gw::Model::Schedule.create_user_prop_view"+
      ":d:" + d.to_s + ":uid:" + uid.to_s + ":sp_mode:" + options[:sp_mode].to_s + ":s_genre:" + options[:s_genre].to_s +
      ":is_gw_admin:" + options[:is_gw_admin].to_s + ":hide_user_col:" + options[:hide_user_col].to_s

    sche = Gw::Schedule.new
    genre = get_prop_modelname(params)
    d2 = d + 6

    cond = (uid.nil? ? '' : "gw_schedule_props.prop_type = '#{genre}' and gw_schedule_props.prop_id = #{uid} and ") +
        " !('#{d.strftime('%Y-%m-%d 0:0:0')}' > gw_schedules.ed_at" +
          " or '#{d2.strftime('%Y-%m-%d 23:59:59')}' < gw_schedules.st_at)"

    cond += " and (gw_schedule_props.extra_data not like '%\"cancelled\":1%' or gw_schedule_props.extra_data is null)"
    cond += " and gw_schedules.is_public != 1"

    prop_cond = "prop_id = #{uid}"
    sche.class.has_many :schedule_props_temp, :foreign_key => :schedule_id,
      :class_name => 'Gw::ScheduleProp', :dependent=>:destroy,
      :conditions => prop_cond
    sches = sche.find(:all, :order => 'allday DESC, gw_schedules.st_at, gw_schedules.ed_at',
      :joins => :schedule_props, :conditions => cond, :select => "gw_schedules.id")

    begin
        value = CACHE.get c_key
        if value.blank? || sches.length > 0
          value = self.create_user_prop_view(d, uid, params, options)
          CACHE.set c_key, value unless sches.length > 0
        else
        end
    rescue
     value = self.create_user_prop_view(d1, d2, uid, params, options)
    end
    return value
  end

  def self.show_schedule_move_core(ab, my_url, qs)
    idx=0
    ret = <<-EOL
#{_ret='';ab.each {|x|
  idx+=1
  href = my_url.sub('%d', "#{(x[0]).strftime('%Y%m%d')}").sub('%q', "#{qs}")
  #_ret += ' ' if idx != 1
  if x[1] == '前週'
    _ret += %Q(<a href="#{href}" class="last_week">#{x[1]}</a>)
  elsif x[1] == '前日'
    _ret += %Q(<a href="#{href}" class="yesterday">#{x[1]}</a>)
  elsif x[1] == '今日'
    _ret += %Q(<a href="#{href}" class="today">#{x[1]}</a>)
  elsif x[1] == '翌日'
    _ret += %Q(<a href="#{href}" class="tomorrow">#{x[1]}</a>)
  elsif x[1] == '翌週'
    _ret += %Q(<a href="#{href}" class="following_week">#{x[1]}</a>)
  elsif x[1] == '前年'
    _ret += %Q(<a href="#{href}" class="last_year">#{x[1]}</a>)
  elsif x[1] == '前月'
    _ret += %Q(<a href="#{href}" class="last_month">#{x[1]}</a>)
  elsif x[1] == '今月'
    _ret += %Q(<a href="#{href}" class="this_month">#{x[1]}</a>)
  elsif x[1] == '翌月'
    _ret += %Q(<a href="#{href}" class="following_month">#{x[1]}</a>)
  elsif x[1] == '翌年'
    _ret += %Q(<a href="#{href}" class="following_year">#{x[1]}</a>)
  else
    _ret += %Q(<a href="#{href}">#{x[1]}</a>)
  end
};_ret}
EOL
    ret
  end
end
