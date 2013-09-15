module Gw::Model::Schedule

  def self.timeout_cancelled
    daytime = Time.now
    daytime_time = daytime - 30 * 60
    daytime_str = daytime_time.strftime("%Y-%m-%d %H:%M:%S")

    cond = "prop_type = 'Gw::PropRentcar' and extra_data is null" +
      " and ((st_at > updated_at and st_at < '#{daytime_str}') or (st_at <= updated_at and updated_at < '#{daytime_str}'))"

    items = Gw::ScheduleProp.new.find(:all, :conditions=>cond, :order=>"st_at, prop_id")

    items.each do |item|

      cond_sub = "prop_type = 'Gw::PropRentcar' and prop_id = #{item.prop_id}" +
        " and st_at < '#{item.st_at.strftime("%Y-%m-%d %H:%M:%S")}' and (extra_data not like '%\"cancelled\":1%' or extra_data is null)"
      item_sub = Gw::ScheduleProp.new.find(:first, :conditions=>cond_sub, :order=>"st_at desc")

      cancel_flg = false
      if item_sub.blank?
        cancel_flg = true
      else
        if item_sub.prop_stat.to_i > 3
          cancel_flg = true
        elsif item_sub.prop_stat.to_i == 3
          if item_sub.ed_at < daytime_time
            cancel_flg = true
          end
        else
          cancel_flg = false
        end

        if cancel_flg
          item.cancel
          item.save
        end
      end

    end

  end

  def self.remind
    item = Gw::Schedule.new
    d = Date.today
    if Site.user
      item.and 'class_id', 1
      item.and 'uid', Site.user.id
    end
    items = item.find(:all, :order => 'st_at, ed_at', :joins => :schedule_users,
      :conditions => "gw_schedule_users.class_id = 1 and gw_schedule_users.uid = #{Site.user.id}" +
        " and (#{Gw.date_between_helper :st_at, d, d+2} or #{Gw.date_between_helper :ed_at, d, d+2})")
    ret_ary = []
    items.each do |x|
      date_str = "#{x.st_at.strftime("%m/%d %H:%M")}-" +
        ( x.st_at.strftime("%m/%d") != x.ed_at.strftime("%m/%d") ? x.ed_at.strftime("%m/%d ") : '' ) +
        x.ed_at.strftime("%H:%M")
      title_str = %Q[<a href="/gw/schedules/#{x.id}/show_one">#{x.title}</a>]
      if x.creator_uid != Site.user.id
        uw = System::User.find(:first, :conditions => "id=#{x.creator_uid}")
        title_str += " (#{uw.groups[0].name.strip} #{uw.name.strip})"
      end
      ret_ary.push({:date_str => date_str,
        :cls => 'スケジュール',
        :title => title_str})
    end
    return ret_ary
  end

  def self.user_left_header(d, uid, params={}, options={})
    td_d = d
    td_s = td_d.strftime("%Y%m%d")
    td1 = Date.new(d.year, d.month, 1)
    td1_s = td1.strftime("%Y%m%d")

    if options[:captions_hash].blank?
    	captions_hash = Gw::NameValue.get_cache('yaml', nil, 'gw_schedules_settings_system_default')
    else
        captions_hash = options[:captions_hash]
    end

    if options[:user].blank?
      caption_main_s = get_user(uid).display_name
    else
      caption_main_s = "#{options[:user].name} (#{options[:user].code})"
    end

    if options[:view] == :day
      if options[:user].code == '000001_0'
        if Gw::Schedule.is_schedule_pref_admin?
         caption_main_s += "#{Gw::Model::Schedule.show_schedule_edit_icon(d, :uid=>uid)}"
        end
     elsif options[:view] == :day
       if ( params[:cgid].blank? ||
          ( !params[:cgid].blank? && System::CustomGroupRole.new.editable?( params[:cgid], Site.user_group.group_id, Site.user.id ) ) )
         caption_main_s += "#{Gw::Model::Schedule.show_schedule_edit_icon(d, :uid=>uid)}"
       end
     end
   end

    day_or_week_link = if options[:view] == :day
      "<a class=\"weekLink\" href=\"/gw/schedules/?s_date=#{td_s}&amp;uid=#{uid}\">#{captions_hash['weekview_button_caption']}</a>"
    else
      "<a class=\"dayLink\" href=\"/gw/schedules/#{td_s}?uid=#{uid}\">#{captions_hash['dayview_button_caption']}</a>"
    end
    month_link = "<a class=\"monthLink\" href=\"/gw/schedules/show_month?s_date=#{td1_s}&amp;uid=#{uid}\">#{captions_hash['monthview_button_caption']}</a>"
    lists_link = "<a class=\"listsLink\" href=\"/gw/schedule_lists/?uid=#{uid}&amp;s_year=#{d.year}&amp;s_month=#{d.month}\">一覧</a>"

    ret = ''
    if params[:cgid].blank?
      ret += '<div class="left-header">' +
        '<div class="username">' + '<span>' + caption_main_s + '</span>' +
        "<span class=\"linkBox\">" + day_or_week_link + month_link + lists_link + '</span>' +
        '</div>' +
        '</div>'
    else
      h_class = options[:user].user_custom_groups_temp[0].icon.blank? ? "userIcon1" : "userIcon"+options[:user].user_custom_groups_temp[0].icon
      ret += '<div class="leftHeader '+ h_class + '">' +
       '<div class="title">'+ options[:user].user_custom_groups_temp[0].title.to_s + '</div>' +
       "<div class=\"username\"><span>#{caption_main_s}</span>" +
        "<span class=\"linkBox\">" + day_or_week_link + month_link + lists_link + '</span>' +
       "</div>" +
       '</div>'
    end

    ret += <<-EOL if false
<div class="link dayLink nobr#{options[:view]!=:day ? '' : ' current'}"><a href="/gw/schedules/#{td_s}?uid=#{uid}">#{captions_hash['dayview_button_caption']}</a></div>
<div class="link weekLink nobr#{options[:view]!=:week ? '' : ' current'}"><a href="/gw/schedules/?s_date=#{td_s}&amp;uid=#{uid}">#{captions_hash['weekview_button_caption']}</a></div>
<div class="link monthLink nobr"><a href="/gw/schedules/show_month?s_date=#{td1_s}&amp;uid=#{uid}">#{captions_hash['monthview_button_caption']}</a></div>
EOL
    return ret
  end

  def self.group_left_header(d, uid, params={}, options={})

    group_item = get_group(:gid=>uid)

    if options[:user].blank?
      caption_main_s = group_item.name
    else
      caption_main_s = group_item.name + "（" + group_item.code + "）"
    end

    ret = ''
    ret += '<div class="leftHeader">' +
        '<div class="username">'+ caption_main_s +'</div>' +
        '</div>'

    if options[:csv]
      return caption_main_s
    else
      return ret
    end
  end

  def self.create_user_prop_view_cache(d, uid, params, options={})
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
     value = self.create_user_prop_view(d, uid, params, options)
    end
    return value
  end

  def self.delete_user_prop_view_cache(d, uid, options={})
    c_key = "Gw::Model::Schedule.create_user_prop_view"+
      ":d:" + d.to_s + ":uid:" + uid.to_s + ":sp_mode:" + options[:sp_mode].to_s + ":s_genre:" + options[:s_genre].to_s +
      ":is_gw_admin:" + options[:is_gw_admin].to_s + ":hide_user_col:" + options[:hide_user_col].to_s
    CACHE.delete( c_key )
  end

  def self.delete_user_prop_view_day_cache(d, uid, options={})
      c_key = "Gw::Model::Schedule.create_user_prop_day_view"+
        ":d:" + d.to_s + ":uid:" + uid.to_s + ":sp_mode:" + options[:sp_mode].to_s + ":s_genre:" + options[:s_genre].to_s +
        ":is_gw_admin:" + options[:is_gw_admin].to_s
    CACHE.delete( c_key )
  end

  def self.delete_user_prop_view_cache_action(st_day, ed_day, today, prop_id, sp_mode, s_genre)
    week_days = (st_day..ed_day).to_a
    week_days.each do |week_day|
      self.delete_user_prop_view_cache(week_day, prop_id, {:sp_mode => sp_mode, :s_genre => s_genre, :is_gw_admin => nil, :hide_user_col => nil})
      self.delete_user_prop_view_cache(week_day, prop_id, {:sp_mode => sp_mode, :s_genre => s_genre, :is_gw_admin => true, :hide_user_col => nil})
    end

    if today.wday == 0
      sunday = today
      monday = sunday - 6
    elsif today.wday == 1
      monday = today
      sunday = monday - 1
    else
      sunday = today - today.wday
      monday = sunday + 1
    end

    month_days = [sunday, monday]
    month_days.each do |month_day|
      self.delete_user_prop_view_cache(month_day, prop_id, {:sp_mode => sp_mode, :s_genre => s_genre, :is_gw_admin => nil, :hide_user_col => true})
      self.delete_user_prop_view_cache(month_day, prop_id, {:sp_mode => sp_mode, :s_genre => s_genre, :is_gw_admin => true, :hide_user_col => true})
    end
    self.delete_user_prop_view_day_cache(today, prop_id, {:sp_mode => sp_mode, :s_genre => s_genre, :is_gw_admin => nil})
  end

  def self.create_user_prop_view(d, uid, params, options={})
    dv = options[:dv] || Time.now
    out_count = nz(options[:count], 0)
    sp_mode = options[:sp_mode]

    items = sp_mode == :schedule ? select_my_data(d, d+6, uid, options) :
      select_prop_data(d, d+6, uid, params, options)

    lns = options[:lns] + 1
    ret = '<tr class="scheduleTableBody lineNo' + lns.to_s + '">'
    ret += %Q(<th class="scheduleUser">#{sp_mode == :schedule ? user_left_header(d, uid, params, :view=>:week, :user=>options[:user], :captions_hash => options[:captions_hash] ) :
      prop_left_header(d, uid, params[:s_genre], params, :view=>:week , :captions_hash => options[:captions_hash], :type_id => options[:type_id], :is_gw_admin => options[:is_gw_admin])}</th>) if options[:hide_user_col].nil?

    csv_str = ""
    if options[:csv]
      csv_left_str = group_left_header(d, uid, params, :view=>:week, :user=>options[:user] , :captions_hash => options[:captions_hash], :csv => options[:csv])
      csv_str = "\"#{csv_left_str}\","
    end

    7.times { |i|
      class_s = %Q(scheduleData #{Gw.weekday_s(d+i, :mode=>:eh, :no_weekday=>1, :holidays=>options[:holidays])})
      class_s += ' rangeOut' unless (d+i).year == dv.year && (d+i).month == dv.month
      class_s += ' today' if (d+i) == Date.today
      class_s += ' selectDay' if (d+i) == nz(params[:s_date], Date.today.to_s).to_date
      ret += %Q(<td class="#{class_s}">)
      cnt = 0
      csv_str += '"'
      item_date = item_date_old = ""
      items.each { |item|
        if item[:date] == d + i
          item_date = item[:date]
          out_count += 1
          cnt += 1
          options[:cnt] = cnt
          opt_view = Gw.extract(options, :keys=>%w(request mode sp_mode cnt csv schedule_settings is_gw_admin))
          str = translate_one_schedule_for_view( item, out_count, opt_view )
          str = "\n" + str if item_date_old == item_date
          item_date_old = item[:date]
          if options[:csv]
            csv_str += str.gsub('"', '""')
          else
            ret += str
          end
        end
      }
      csv_str += '",'

      if sp_mode == :schedule
        if options[:user].code == '000001_0'
         if Gw::Schedule.is_schedule_pref_admin?
            ret += show_schedule_edit_icon(d+i, :uid=>uid)
         end
        else
         if ( params[:cgid].blank? ||
          ( !params[:cgid].blank? && System::CustomGroupRole.new.editable?( params[:cgid], Site.user_group.group_id, Site.user.id ) ) )
            ret += show_schedule_edit_icon(d+i, :uid=>uid)
         end
        end
      elsif sp_mode == :event
        ret += ""
      elsif sp_mode == :prop
        if options[:is_prop_edit]
          ret += show_schedule_edit_icon(d+i, :prop_id=>uid, :s_genre=>params[:s_genre], :be=>params[:be])
        end
      else
        ret += show_schedule_edit_icon(d+i, :prop_id=>uid, :s_genre=>params[:s_genre])
      end
      ret += "\n</td>\n"
    }
    if options[:csv]
      return csv_str
    else
      return [ret + '</tr>', out_count]
    end
  end

  def self.show_schedule_edit_icon(d, options={})
    par_a = [%Q(s_date=#{(d).strftime("%Y%m%d")})]
    par_a.push "uid=#{options[:uid]}" if !options[:uid].nil?
    par_a.push "prop_id=#{options[:prop_id]}" if !options[:prop_id].nil?
    par_a.push "s_genre=#{options[:s_genre]}" if !options[:s_genre].nil?
    par_a.push "be=#{options[:be]}" if !options[:be].nil?
    par_s = Gw.a_to_qs(par_a);
    %Q(<a href="/gw/schedules/new#{par_s}"><img src="/_common/themes/gw/files/schedule/ic_add.gif" alt="edit" width="15" height="15" align="top" /></a>)
  end

  def self.select_my_data(d1, d2, uid, options={})
    return [] if uid.nil? && (Site.user.nil? || Site.user.id.nil?)
    uid = Site.user.id if uid.nil?

    gid = options[:user] ? options[:user].user_groups[0].id : get_group(:uid=>uid).id

    sche = Gw::Schedule.new
    cond_date = "!('#{d1.strftime('%Y-%m-%d 0:0:0')}' > gw_schedule_users.ed_at" +
          " or '#{d2.strftime('%Y-%m-%d 23:59:59')}' < gw_schedule_users.st_at)"
    cond = "((gw_schedule_users.class_id = 1 and gw_schedule_users.uid = #{uid}) or (gw_schedule_users.class_id = 2 and gw_schedule_users.uid = #{gid}))" +
        " and #{cond_date}"
    sche.class.has_many :schedule_props_temp, :foreign_key => :schedule_id,
      :class_name => 'Gw::ScheduleProp', :dependent=>:destroy,
      :conditions => 'prop_id is null'
    sches = sche.find(:all, :order => 'gw_schedules.allday DESC, gw_schedule_users.st_at, gw_schedule_users.ed_at, gw_schedules.id',
      :joins => :schedule_users, :conditions => cond,
      :include => [:schedule_props_temp,
            {:schedule_users => [ {:user => [:user_groups], :group => [:user_group] } ] }
      ]
    )

    ret = []

    schedule_parent_ids = []
    sches.each do |item|
      if !item.schedule_prop.blank?  && item.schedule_prop.is_kanzai? < 3 && item.schedule_prop.cancelled? # キャンセルは非表示
      else
        if item.schedule_parent_id.blank?
          ret += self.translate_one_schedule(item, options)
        else
          if schedule_parent_ids.blank? || schedule_parent_ids.index(item.schedule_parent_id).blank?
            schedule_parent_ids << item.schedule_parent_id
            ret += self.translate_one_schedule(item, options)
          end
        end
      end
    end

    if !options[:holidays].blank?
     options[:holidays].each { |item|
       next if item.ed_at.nil?
       title = "#{item.title}"
       ret.push({:date => Gw.datetime_to_date(item.ed_at),
        :title_raw => "#{item.title}",
        :id => "holiday#{item.id}", :item => item, :genre => :holiday})
      }
    end

    if uid == Site.user.id && options[:todo] == true
      todos_settings = Gw::Model::Schedule.get_settings 'todos',{:uid=>uid}
      if !todos_settings['todos_display_schedule'].blank? && todos_settings['todos_display_schedule'].to_i == 1
        todos_cond = "class_id = 1 and uid = #{uid}" +
          " and '#{d1.strftime('%Y-%m-%d 0:0:0')}' <= ed_at" +
          " and '#{d2.strftime('%Y-%m-%d 23:59:59')}' >= ed_at"
        todos = Gw::Todo.find(:all, :conditions => todos_cond)
        todos.each { |item|
        ret.push({:date => Gw.datetime_to_date(item.ed_at),
         :title => item.title,
         :delay => item.ed_at.nil? ? false : Time.now > item.ed_at,
         :title_raw => "[ToDo] #{item._title}",
         :title_link => "/gw/todos/" + item.id.to_s,
         :class => 'category800',
         :id => "todo#{item.id}", :item => item, :genre => :todo})
        }
      end
    end

    return ret.select{|x| Gw.date_in_range?(x[:date], d1, d2)}
  end


  def self.translate_one_schedule(item, options={})

    da = Gw.date_array(item.st_at, item.ed_at)
    ret = []
    sp_mode = options[:sp_mode]

    is_gw_admin = options[:is_gw_admin]
    unless defined? is_gw_admin
      is_gw_admin = Gw.is_admin_admin?
    end

    prop = item.schedule_prop

    if da.length > 0
      ret_p = {:st_at=>item.st_at, :ed_at=>item.ed_at, :id=>"sche#{item.id}", :item=>item}
      title = if options[:mode] == :prop_pm
        confirmed = prop.confirmed?
        confirmed_s = confirmed.nil? ? '' : " [#{Gw::ScheduleProp.confirmed_s(confirmed)}]"
        "#{item.owner_gname}#{confirmed_s}"
      else
        item.title
      end

      common_condition =  item.is_public_closed_auth?(is_gw_admin)

      if common_condition
        ret_p[:title_raw] = '[非公開予定]'
        ret_p[:title] = ret_p[:title_raw]
      else
        ret_p[:title_raw] = title

        if sp_mode == :event
          title_class_a = ""
        elsif !prop.blank? && sp_mode == :prop
          title_class_a = [nz(prop.prop_stat,0) == '' || prop.prop_stat == nil ? 'category1' : "category#{nz(prop.prop_stat_category_id, 0)}"]  # matsuki 追加 10/04/30 貸出前=0、貸し出し中=2、返却=3
        else

          title_class_a = [nz(item.title_category_id,'') == '' ? 'category0' : "category#{item.title_category_id}"]
          title_class_a.push confirmed.nil? ? '' : confirmed ? 'confirmed' : 'unconfirmed'

        end

        title_class_s = Gw.join(title_class_a) if !title_class_a.blank?

        if sp_mode == :schedule || sp_mode == :event
          link = "/gw/schedules/#{item.id}/show_one?sh=sh"
        else
          link = "/gw/schedules/#{item.id}/show_one"
        end

        title = %Q(#{Gw.helperx.link_to title, link, :class=>title_class_s})
        ret_p[:title] = title
        ret_p[:title_link] = link
        ret_p[:class] = title_class_s
        ret_p[:genre] = :schedule
        ret_p[:s_genre] = options[:s_genre]
      end
      ret_p[:allday] = item.allday

      ret_p[:created_at] = item.created_at
      ret_p[:memo]       = item.memo if !item.memo.blank?
      ret_p[:place]      = item.place if !item.place.blank?

      kind_str = ""
      ret_p[:event_kind] = kind_str

      ret_p[:user_names] = item.get_usernames
      ret_p[:is_prop_type] = item.is_prop_type?
      ret_p[:prop_names] = item.get_propnames

          case da.length
          when 1
             ret.push ret_p.merge({:date => da[0], :time_str => "#{Gw.time_str(item.st_at)}-#{Gw.time_str(item.ed_at)}"})
          when 2
            ret.push ret_p.merge({:date => da[0], :time_str => "#{Gw.time_str(item.st_at)}-"})
            ret.push ret_p.merge({:date => da[1], :time_str => "-#{Gw.time_str(item.ed_at)}"})
          else
            idx = 0
            for d in da
              idx += 1
              case idx
              when 1
                ret.push ret_p.merge({:date => d, :time_str => "#{Gw.time_str(item.st_at)}-"})
              when da.length
                ret.push ret_p.merge({:date => d, :time_str => "-#{Gw.time_str(item.ed_at)}"})
              else
                ret.push ret_p.merge({:date => d, :time_str => ""})
              end
            end
          end

    end
    return ret
  end

  def self.translate_one_schedule_for_view(item, out_count, options={})

    _item = item[:item] # スケジュール、もしくは休日,todo
    sp_mode = options[:sp_mode]
    genre = item[:genre]
    s_genre = item[:s_genre]

    ret = ''

    if genre == :schedule && sp_mode == :event && _item.stepped_over?
      if !_item.stepped_st_date_today?(item[:date])
        return "" # 日が当日でないなら、その日は表示させない。
      end
    end

    title_raw = item[:title_raw]
    title_raw = if item[:allday] == 1
      #%Q(<span class="allday">時間未定</span>)
      %Q(（時間未定） #{title_raw})
    elsif item[:allday] == 2
      #%Q(<span class="allday">終日</span>)
      %Q(#{title_raw})
    else
      %Q(#{title_raw})
    end

    csv_base_str = title_raw

    # スケジュール設定が場所表示の場合
    if sp_mode != :event && !_item.is_a?(Gw::Todo) &&
      options[:schedule_settings][:view_place_display] == '1' &&
      !item[:title_link].blank? && !item[:item].place.blank?
      title_raw = "<span class=\"title\">#{title_raw}</span><span class=\"place\">（#{item[:item].place}）</span>"
    end

    # CSV出力
    if options[:csv]
      if item[:allday].blank?
        csv_base_str = "#{item[:time_str]} " + csv_base_str + csv_parent_str
      else
        csv_base_str = csv_base_str + csv_parent_str
      end
    end

    base_s = case options[:mode]
    when 'day'
      if item[:allday] == 1
        #%Q(<span class="allday">時間未定</span>)
        %Q(#{title_raw})
      elsif item[:allday] == 2
        #%Q(<span class="allday">終日</span>)
        %Q(#{title_raw})
      else
        %Q(#{title_raw})
      end

    else
      if s_genre.blank?
        if item[:allday] == 1
          %Q(<span>#{title_raw}</span>)
        elsif item[:allday] == 2
          %Q(<span>#{title_raw}</span>)
        else
          %Q(<span>#{item[:time_str]}</span><br /> #{title_raw})
        end
      else
        %Q(<span>#{item[:time_str]}</span> #{title_raw})
      end
    end
    if item[:title_link].nil?
      value_s =  base_s
      title_s = base_s
    else
        value_s =  Gw.helperx.link_to(base_s, item[:title_link], :class=>item[:class])
        if item[:allday] == 1 || item[:allday] == 2
          #value_s +=  Gw.helperx.link_to("#{item[:title_raw]}", item[:title_link], :class=>"title")
        end

      title_a = []

      is_ie = Gw.ie?(options[:request])

      if _item.is_a? Gw::Schedule

        part_num_a = []
        part_num_a.push "庁内#{_item.participant_nums_inner}人" if !nf(_item.participant_nums_inner).blank?
        part_num_a.push "庁外#{_item.participant_nums_outer}人" if !nf(_item.participant_nums_inner).blank?
        part_num_a = ['利用人数：'] + part_num_a if part_num_a.length > 0

        title_category = Gw.yaml_to_array_for_select('gw_schedules_title_categories').to_a.rassoc(_item.title_category_id.to_i) # 件名カテゴリ
        is_public = Gw.yaml_to_array_for_select('gw_schedules_public_states').to_a.rassoc(_item.is_public.to_i) # 公開範囲
        title = "件名：" + "#{"【" + title_category[0] + "】 " if !title_category.blank?}#{_item.title}"
        place = _item.place.blank? ? "" :"場所： #{_item.place}"
        memo = _item.memo.blank? ? "" : is_ie ? "メモ： " + _item.memo : "メモ： " + Gw.br(_item.memo)
        inquire_to = _item.inquire_to.blank? ? "" : "連絡先： #{_item.inquire_to}"
        public = is_public.blank? ? nil : "公開範囲： #{is_public[0]}"
        event_kind = item[:event_kind].blank? ? "" : "広報： #{item[:event_kind]}"
        user_names = !item[:user_names].blank? ? "参加者： #{item[:user_names]}" : ""
        prop_names = !item[:prop_names].blank? ? "施設： #{item[:prop_names]}" : ""

          title_a += [title,
            place,
            memo,
            !item[:is_prop_type].blank? && item[:is_prop_type] >= 1 ? inquire_to : "",
            public,
            event_kind,
            user_names,
            !item[:is_prop_type].blank? && item[:is_prop_type] >= 1 ? prop_names : ""
          ]

      elsif _item.is_a? Gw::Todo
        title_a += [ "期限： " + item[:date].to_s,
          "内容： " + _item[:title]
        ]

      end
      title_s = Gw.join(title_a, options[:request].nil? || !is_ie ? '<br/>' : "\n")

    end

    item[:allday].blank? ? class_a = ['ind', item[:delay] ? ' expired' : ''] : class_a = ['ind', item[:delay] ? ' expired' : '']

    class_s = Gw.join(class_a, ' ')
    title_s = Gw.simple_strip_html_tags title_s, :exclude_tags=>'br/'
    ret += %Q(<div id="#{item[:id]}_#{out_count}" class="#{class_s}" title="#{title_s}">#{value_s}</div>)
    if options[:csv]
      return csv_base_str
    else
      return ret
    end
  end

  def self.show_schedule_move_core(ab, my_url, qs)
    idx=0
    ret = <<-EOL
#{_ret='';ab.each {|x|
  idx+=1
  href = my_url.sub('%d', "#{(x[0]).strftime('%Y%m%d')}").sub('%q', "#{qs}")
  _ret += ' ' if idx != 1
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

  def self.get_user(uid)
    System::User.find(:first, :conditions => "id=#{uid}")
  end

  def self.get_users_id_in_group(gid)
    return [] unless System::Group.find(:first, :conditions => "id=#{gid}")
    return System::UsersGroup.find(:all, :conditions => "group_id=#{gid}", :joins => :user, :order => "code").reject{|x| x.user.state != 'enabled'}.collect{|x| x.user_id }
  end

  def self.get_uids(params)
    if !params[:gid].blank?
      gid = params[:gid]
      if gid =='me'
        gid = Site.user.groups[0].id
      elsif /^\d+$/ !~ gid
        return []
      end
      uids = get_users_id_in_group(gid)
      uids = [Site.user.id] if uids.length == 0

    elsif !params[:cgid].blank?
      cgid = params[:cgid]
      uids = System::UsersCustomGroup.find(:all,
        :conditions => "custom_group_id = #{cgid}",
        :order => "sort_no"
        ).collect{|x| x.user_id }
    else
      uid = params[:uid]
      uid = Site.user.id if uid.nil? || uid == 'me'
      if uid == 'all'
        return System::User.find(:all, :conditions => "state='enabled'").collect{|x| x.id}, nil
      end
      uid = uid.to_i rescue Site.user.id
      uid = Site.user.id if System::User.find(:all, :conditions => "id=#{uid}").length == 0
      uids = [uid]
    end
    return uids
  end

  def self.get_users(params)
    if !params[:gid].blank?

      gid = params[:gid]
      if gid =='me'
        gid = Site.user.groups[0].id
      elsif /^\d+$/ !~ gid
        return []
      end

      users =  System::User.find(:all,
        :conditions => "system_users_groups.group_id=#{gid} AND system_users.state = 'enabled' and system_users.ldap = 1",
        :joins => :user_groups,
      	:include => :user_groups,
        :order => "system_users.code")
      users = [Site.user] if users.length == 0

    elsif !params[:cgid].blank?

      cgid = params[:cgid]
      if /^\d+$/ !~ cgid
        return []
      end

      u = System::User.new
      u.class.has_many :user_custom_groups_temp, :foreign_key => :user_id,
      :class_name => 'System::UsersCustomGroup', :dependent=>:destroy,
      :conditions => " custom_group_id = #{params[:cgid]}"
      users = u.find(:all,
        :conditions => "system_users.state = 'enabled' AND system_users_custom_groups.custom_group_id = #{cgid}",
        :order => "system_users_custom_groups.sort_no" ,
        :joins => :user_custom_groups_temp,
      	:include => :user_custom_groups_temp
        )

    else

      uid = params[:uid]
      uid = Site.user.id if uid.nil? || uid == 'me'
      if uid == 'all'
        users = System::User.find(:all, :conditions => "state='enabled'")
      else
        if uid == Site.user.id
          users = [Site.user]
        else
          users = System::User.find(:all, :conditions => "id=#{uid}")
        end
      end

    end
    return users
  end

  def self.get_uname(options={})
    case
    when !options[:uid].nil?
      ux = System::User.find(:first, :conditions=>"id=#{options[:uid]}")
      return '' if ux.nil?
      return Gw.trim(nz(ux.display_name))
    else
      return ''
    end
  end
  def self.get_gname(options={})
    case
    when !options[:gid].nil?
      ux = System::Group.find(:first, :conditions=>"id=#{options[:gid]}")
      return '' if ux.nil?
      return Gw.trim(nz(ux.display_name))
    else
      return ''
    end
  end
  def self.get_group(options={})
    return !options[:gid].nil? ? System::Group.find(:first, :conditions=>"id=#{options[:gid]}") :
      !options[:uid].nil? ? System::User.find(:first, :conditions=>"id=#{options[:uid]}").groups[0] : nil
  end

  def self.link_to_prop_master(id, cls, genre, options={})
    caption = nz(options[:caption], '設備情報')
    Gw.helperx.link_to(caption, "/gw/prop_#{genre}s/#{id}?cls=#{cls}")
  end

  def self.prop_left_header(d, prop_id, genre_name, params, options={})
    td_d = d
    td_s = td_d.strftime("%Y%m%d")
    td1 = Date.new(d.year, d.month, 1)
    td1_s = td1.strftime("%Y%m%d")

    if options[:captions_hash].blank?
        captions_hash = Gw::NameValue.get_cache('yaml', nil, 'gw_schedules_settings_system_default')
    else
        captions_hash = options[:captions_hash]
    end

    cls = params[:cls]
    genre_class_s = genre_name.nil? || cls == "other" ? '' : " #{genre_name}"

    if cls == "other"
      if options[:type_id].blank?
        type_id = get_prop_model(params).find(:first, :conditions => "id=#{prop_id} and delete_state = 0").type_id
      else
        type_id = options[:type_id]
      end
      case type_id
      when 200
        genre_class_s += " room"
      when 100
        genre_class_s += " car"
      else
        genre_class_s += " other"
      end

    end

    prop = get_prop(prop_id, params)
    caption_main_s = case cls
    when 'other'
      parent_groups = Gw::PropOther.get_parent_groups
      admin_first_id = prop.admin_first_id(parent_groups)
      group  = System::GroupHistory.find_by_id(admin_first_id)
      "#{prop.name}(#{group.name if !group.blank?})"
    else
      prop.name
    end

      caption_main_s = self.link_to_prop_master prop_id, cls, genre_name, :caption=>caption_main_s
      if options[:view] == :day && Gw::ScheduleProp.is_prop_edit?(prop_id, genre_name, {:prop => prop, :is_gw_admin => options[:is_gw_admin]})
        caption_main_s += "#{Gw::Model::Schedule.show_schedule_edit_icon(d, :prop_id=>prop_id, :s_genre=>genre_name)}"
      end

      day_or_week_link = if options[:view] == :day
        "<a class=\"weekLink\" href=\"/gw/schedule_props/show_week?s_genre=#{genre_name}&amp;s_date=#{td_s}&amp;prop_id=#{prop_id}&amp;cls=#{cls}\">#{captions_hash['weekview_button_caption']}</a>"
      else
        "<a class=\"dayLink\" href=\"/gw/schedule_props/#{td_s}?s_genre=#{genre_name}&amp;prop_id=#{prop_id}&amp;cls=#{cls}\">#{captions_hash['dayview_button_caption']}</a>"
      end
      month_link = "<a class=\"monthLink\" href=\"/gw/schedule_props/show_month?s_genre=#{genre_name}&amp;s_date=#{td1_s}&amp;prop_id=#{prop_id}&amp;cls=#{cls}\">#{captions_hash['monthview_button_caption']}</a> "

      ret = "<div class=\"username#{genre_class_s}\"><span>#{caption_main_s}</span>" +
        "<span class=\"linkBox\">" + day_or_week_link + month_link + '</span>' +
        "</div>"
      if false
      ret += <<-EOL
<div class="link dayLink nobr#{options[:view]!=:day ? '' : ' current'}"><a href="/gw/schedule_props/#{td_s}?s_genre=#{genre_name}&amp;prop_id=#{prop_id}&amp;cls=#{cls}">#{captions_hash['dayview_button_caption']}</a></div>
<div class="link weekLink nobr#{options[:view]!=:week ? '' : ' current'}"><a href="/gw/schedule_props/show_week?s_genre=#{genre_name}&amp;s_date=#{td_s}&amp;prop_id=#{prop_id}&amp;cls=#{cls}">#{captions_hash['weekview_button_caption']}</a></div>
<div class="link monthLink nobr"><a href="/gw/schedule_props/show_month?s_genre=#{genre_name}&amp;s_date=#{td1_s}&amp;prop_id=#{prop_id}&amp;cls=#{cls}">#{captions_hash['monthview_button_caption']}</a></div>
EOL
      end

    ret
  end

  def self.select_prop_data(d1, d2, prop_id, params, options = {})
    return [] if prop_id.nil?
    sche = Gw::Schedule.new

    genre = get_prop_modelname(params)
    cond = (prop_id.nil? ? '' : "gw_schedule_props.prop_type = '#{genre}' and gw_schedule_props.prop_id = #{prop_id} and ") +
        " !('#{d1.strftime('%Y-%m-%d 0:0:0')}' > gw_schedules.ed_at" +
          " or '#{d2.strftime('%Y-%m-%d 23:59:59')}' < gw_schedules.st_at)"
    cond += " and (gw_schedule_props.extra_data not like '%\"cancelled\":1%' or gw_schedule_props.extra_data is null)"
    prop_cond = "prop_id = #{prop_id}"
    sche.class.has_many :schedule_props_temp, :foreign_key => :schedule_id,
      :class_name => 'Gw::ScheduleProp', :dependent=>:destroy,
      :conditions => prop_cond
    sches = sche.find(:all, :order => 'allday DESC, gw_schedules.st_at, gw_schedules.ed_at',
      :joins => :schedule_props, :conditions => cond,
      :include => [:schedule_props_temp,
            {:parent => [:child]},
            :schedule_prop,
            {:schedule_users => [ {:user => [:user_groups], :group => [:user_group] } ] }
      ] )
    ret = []
    opt = {}
    opt[:mode] = :prop_pm if params[:cls]=='pm'
    opt[:prop_id] = prop_id
    opt[:s_genre] = params[:s_genre]
    opt[:sp_mode] = options[:sp_mode]
    opt[:is_gw_admin] = options[:is_gw_admin]
    sches.each { |item|
      ret += self.translate_one_schedule(item, opt)
    }
    return ret.select{|x| Gw.date_in_range?(x[:date], d1, d2)}
  end

  def self.get_prop_modelname(params)
    "Gw::Prop#{Gw.modelize(params[:s_genre])}"
  end

  def self.get_prop_model(params)
    eval("Class.new #{get_prop_modelname(params)}")
  end

  def self.get_prop_ids(params)
    return [] if params[:s_genre].nil?
    return [] if params[:cls].nil? && params[:prop_id].nil?
    if params[:prop_id].nil?
      cond = "delete_state = 0 or delete_state is null"
      _mdl = get_prop_model(params)
      _mdl.find(:all, :conditions=>cond, :order=>'extra_flag, gid, sort_no, name').select{|x|
        case params[:cls]
        when 'other'
          if params[:be] == "other"
            x.gid.to_s != Site.user.groups[0].id.to_s #&& x.state.to_s == "public" # 他所属と自所属の違いが無くなったのでコメント化（10/08/25）
          else
            x.gid.to_s == Site.user.groups[0].id.to_s
          end
        else
          x.extra_flag == params[:cls]
        end
      }.collect{|x| x.id}
    else
      [params[:prop_id]]
    end
  end

  def self.get_prop(prop_id, params)
    _mdl = get_prop_model(params)
    _mdl.find(:first, :conditions => "id=#{prop_id}")
  end

  def self.get_props(params, is_gw_admin = Gw.is_admin_admin?, options = {})

    s_other_admin_gid = options[:s_other_admin_gid].to_i
    group = Site.user.groups[0]
    return [] if params[:s_genre].nil?
    return [] if params[:cls].nil? && params[:prop_id].nil?
    _mdl = get_prop_model(params)
    cond = ""

    cond += " delete_state = 0"
    cond_type = ""

    if is_gw_admin
      if params[:type_id].blank?
        cond_type = " and type_id = 100"
      elsif params[:type_id] == '0'
      else
        cond_type = " and type_id = #{params[:type_id]}"
      end
    else
      cond_type = " and type_id = #{params[:type_id]}" if !params[:type_id].blank? && params[:type_id] != '0'
    end

    cond_other = "delete_state = 0 and (auth = 'read' or auth = 'edit') and ((gw_prop_other_roles.gid = #{group.id} or gw_prop_other_roles.gid = #{group.parent_id}) or (gw_prop_other_roles.gid = 0))"
    cond_other += cond_type

    cond_other_admin = ""
    if is_gw_admin && s_other_admin_gid != 0 # 絞り込み
      s_other_admin_group = System::GroupHistory.find_by_id(s_other_admin_gid)
      s_other_admin_group
      cond_other_admin = "  and auth = 'admin'"
      if s_other_admin_group.level_no == 2 # 部局
        gids = Array.new
        gids << s_other_admin_gid
        parent_groups = System::GroupHistory.new.find(:all, :conditions => ['parent_id = ?', s_other_admin_gid])
        parent_groups.each do |parent_group|
          gids << parent_group.id
        end
        search_group_ids = Gw.join([gids], ',')
        cond_other_admin += " and  gw_prop_other_roles.gid in (#{search_group_ids})"
      else # 所属
        cond_other_admin += " and  gw_prop_other_roles.gid = #{s_other_admin_group.id}"
      end
    end

    if params[:prop_id].nil?
      if params[:s_genre] == 'other'
        other_items = if is_gw_admin
          _mdl.find(:all, :conditions=>cond + cond_type + cond_other_admin, :order=>'type_id, gid, coalesce(sort_no, 0), name',
            :joins => :prop_other_roles, :group => "gw_prop_others.id")
        else
          _mdl.find(:all, :conditions=>cond_other, :order=>'type_id, gid, coalesce(sort_no, 0), name, gw_prop_others.gid',
            :joins => :prop_other_roles, :group => "gw_prop_others.id")
        end

        parent_groups = Gw::PropOther.get_parent_groups

        _items = other_items.sort{|a, b|
            ag = System::GroupHistory.find_by_id(a.admin_first_id(parent_groups))
            bg = System::GroupHistory.find_by_id(b.admin_first_id(parent_groups))
            flg = (!ag.blank? && !bg.blank?) ? ag.sort_no <=> bg.sort_no : 0
            (a.type_id <=> b.type_id).nonzero? or (flg).nonzero? or a.sort_no <=> b.sort_no
        }
        return _items
      else
        _mdl.find(:all, :conditions=>cond, :order=>'extra_flag, gid, sort_no, name').select{|x|
          x.extra_flag == params[:cls]
        }
      end
    else
      _mdl.find(:all, :conditions=>"id = #{params[:prop_id]} and delete_state = 0" )
    end
  end

  def self.get_settings(_key, options={})
    key = _key.to_s
    options[:nodefault] = 1 if !%w(ssos).index(key).nil?
    ret = {}

    if options[:nodefault].nil?
      ret.merge! Gw::NameValue.get_cache('yaml', nil, "gw_#{key}_settings_system_default")
    end

    ind = Gw::Model::UserProperty.get(key.singularize, options)
    if !ind.blank? && !ind[key].blank?
      if key == 'portals'
        ret = ind[key]
        remove_obsolete_rss(ret)
      else
        ret.merge! ind[key]
      end
    end
    return HashWithIndifferentAccess.new(ret)
  end

  def self.remove_obsolete_rss(hh)
    hh.reject! do |item|
      !item[1]['piece_name'].blank? && item[1]['piece_name'].index('piece/gw-rssreader') == 0 if item.length >= 2
    end
  end

  def self.get_ind_portal_add_cands_all
    sql = Condition.new
    sql.and :state, 'public'
    sql.and :view_hide , 1
    sql.and "sql", "gwbbs_roles.role_code = 'r'"
    sql.and "sql", "gwbbs_roles.group_code = '0'"

    join = "INNER JOIN gwbbs_roles ON gwbbs_controls.id = gwbbs_roles.title_id"
    items = Gwbbs::Control.find(:all, :joins=>join, :conditions=>sql.where,:order => 'sort_no, updated_at DESC', :group => 'gwbbs_controls.id')
    add_cands = []

    add_cands += items.sort{|a,b|a.sort_no<=>b.sort_no}.collect{|x|["#{x.id}", "掲示板/#{x.title}", 'gwbbs']}
    add_cands += [["3", "新着情報", 'gwbbs']]
    add_cands
  end

  def self.cut_strng(strng, cut_num, strt_pnt = 0)
    if cut_num == nil || cut_num == 0 then
      return ''
    else
      end_pnt = strt_pnt + cut_num
    end
    if end_pnt >= jp_chr_num(strng) then
      end_pnt = jp_chr_num(strng)-1
    end
    if strt_pnt > end_pnt then
      return ''
    end
    strng_chrs = Array.new
    strng_chrs = strng.split(//u)
    cut_strng = ''
    strt_pnt.upto(end_pnt) do |x|
      cut_strng += strng_chrs[x]
    end
    return cut_strng
  end
end
