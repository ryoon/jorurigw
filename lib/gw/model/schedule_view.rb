module Gw::Model::Schedule_view

  def self.td(colspan=1, options={})
    caption = options[:caption]
    class_s = Gw.join([:scheduleData, options[:class]], ' ')
    %Q(<td class="#{class_s}" colspan="#{(colspan*2).to_int}">#{caption}</td>)
  end

  def self.td_range(st, ed, options={})
    ret = ''
    (ed - st + 1).times { ret += td 1, options}
    ret
  end

  def self.show_user(r, uid = Site.user.id, d = Date::today, params = {}, items_all = {}, options = {})
    
    out_count = 0
    items = items_all[uid]
    request_url = options[:request_url]
    sp_mode = options[:sp_mode]
    schedule_settings = options[:schedule_settings]
    is_gw_admin = options[:is_gw_admin]
    ln = 0
    allday_flg = false
    allday_cnt = 0

    items.each {|item|
      allday_flg = true if item[:allday] == 1 || item[:allday] == 2
      allday_cnt += 1 if item[:allday] == 1 || item[:allday] == 2
    }

    itemlen = items.length
    allday_flg ? trc = "alldayLine" : trc = "scheduleTableBody categoryBorder"
    trc = "scheduleTableBody" if itemlen == 0
    allday_flg ? row = (items.length * 2) - ((allday_cnt * 2) - 1) : row = items.length * 2

    ret = ''
    ret = <<-EOL
  <tr class="#{trc}">
  <th class="scheduleUser" rowspan="#{items.length == 0 ? 1 : row}">
  #{sp_mode == :schedule ? Gw::Model::Schedule.user_left_header(d, uid, params, :view=>:day, :user=>options[:user]) :
    Gw::Model::Schedule.prop_left_header(d, uid, params[:s_genre], params, :view=>:day, :is_gw_admin => is_gw_admin)}
  </th>
  EOL
    if items.length == 0
      ret += self.td_range(r.first, r.last)
      ret += '</tr>'
    else
    col = ((r.last - r.first) * 2) + 2
      items.each {|item|
        if !item[:allday].blank?
          ret += "<td colspan=\"#{col}\">" if ln == 0 && allday_flg
          ret += Gw::Model::Schedule.translate_one_schedule_for_view(item, 1, {:no_image=>1,
              :request=>request_url, :mode=>'day', :schedule_settings => schedule_settings, :is_gw_admin => is_gw_admin, :sp_mode => sp_mode})
          ret += '</td>' if ln == allday_cnt && allday_flg
        else
          ret += '<tr class="scheduleTableBody categoryBorder">' if ln != 0
          _item = item[:item]
          if _item.ed_at.to_date > d
            ed_at = 23.5
          else
            ed_at = _item.ed_at.hour
            ed_at += 0.5 if _item.ed_at.min > 30
            ed_at -= 0.5 if _item.ed_at.min == 0 && ed_at != 0 && _item.st_at != _item.ed_at
          end
          if _item.is_a?(Gw::Schedule)
            if item[:st_at].to_date < d
              st_at = 0
            else
              st_at = item[:st_at].hour
              st_at += 0.5 if item[:st_at].min >= 30
            end
          else
            st_at = ed_at
          end
          ((st_at - (r.first)).floor).times { ret += self.td }
          ret += self.td(0.5) if st_at != st_at.floor
          len = ed_at - st_at + 0.5
          if len == 0 && _item.ed_at == _item.st_at
            len = 0.5
            ed_at += 0.5
          end
          out_count += 1
          ret += self.td(len, :caption=>Gw::Model::Schedule.translate_one_schedule_for_view(item, out_count, {:sp_mode => sp_mode, :no_image=>1,
                :request=>request_url, :mode=>'day', :schedule_settings => schedule_settings, :is_gw_admin => is_gw_admin, :sp_mode => sp_mode}))
          ret += self.td(0.5) if ed_at == ed_at.floor
          (((r.last) - ed_at).ceil).times { ret += self.td }
          ret +='</tr>'
          ret +='<tr class="scheduleTableBody explanation">' if itemlen != ln + 1
          ret +='<tr class="scheduleTableBody explanation end">' if itemlen == ln + 1
          ((st_at - (r.first)).floor).times { ret += self.td }
          ret += self.td(0.5) if st_at != st_at.floor
          ret += "<td colspan=\"#{(((r.last - st_at) * 2) + 2)}\">"
          item_st_at = item[:st_at].to_date
          item_ed_at = item[:ed_at].to_date
          if ed_at == 23.5
            if len == 24
              ret += "#{item[:title_raw]}"
            elsif item_st_at == d
              ret += "#{item[:st_at].strftime("%H:%M")} -　　#{item[:title_raw]}"
            end
          elsif st_at == 0 && item_st_at != item_ed_at
            ret += "- #{item[:ed_at].strftime("%H:%M")}　　#{item[:title_raw]}"
          else
            ret += "#{item[:st_at].strftime("%H:%M")} - #{item[:ed_at].strftime("%H:%M")}  #{item[:title_raw]}"
          end
        if schedule_settings[:view_place_display] == '1'
            ret += "（#{item[:item].place}）" if !item[:item].place.blank?
        end
          ret += "</td>"
          ret +='</tr>'
        end
        ln += 1
      }
    end
    ret
  end

end