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

end
