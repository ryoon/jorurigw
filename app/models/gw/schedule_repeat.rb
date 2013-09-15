class Gw::ScheduleRepeat < Gw::Database
  include System::Model::Base
  include Cms::Model::Base::Content
  has_many :schedules, :foreign_key => :schedule_repeat_id, :class_name => 'Gw::Schedule', :dependent=>:destroy

  def self.save_with_rels_concerning_repeat(item, params, mode)
    raise "update/create 以外は未実装です" if %w(update create).index(mode.to_s).nil?

    form_kind_id = params[:item][:form_kind_id]
    if form_kind_id == "0"
      params[:item][:inquire_to] = ""
      params[:item][:schedule_props_json] = "[]"
    end

    _props = JsonParser.new.parse(params[:item][:schedule_props_json])

    has_pm = 0; has_ot_ot = 0; ot_ot_ids = []
    _masters = {'other'=>Gw::PropOther}
    prop_details = []
    _props.each{|x|
      _x = x
      _genre, _id = x[0], x[1]
      _x.push _masters[_genre].find(:first, :conditions=>"id=#{_id}")
      prop_details.push _x
    }
    prop_details.each{|x|
      _genre, _id, _prop = x[0], x[1], x[3]
      if nz(_prop.extra_flag, 'other') == 'pm' || nz(_prop.extra_flag, 'other') == 'other'
        has_pm += 1
        if x[0] == 'other'
          has_ot_ot += 1
          ot_ot_ids.push _id
        end
      end
    }

    is_gw_admin = Gw.is_admin_admin?

    if mode == :update
      cg = Gw::Model::Schedule.get_group(:gid => item.creator_gid)
    else
      if params[:item][:creator_uid].blank?
        cu = Site.user
      else
        cu = System::User.get(item[:creator_uid])
      end
      cg = cu.groups[0]
    end

    ouid = params[:item][:owner_uid]
    if ouid.blank?
      item.errors.add :owner_udisplayname, 'は空欄となっています。ユーザーを指定してください。'
      return false
    end

    kanzai_flg = false
    prop_flg = false
    prop_flg = true if kanzai_flg || has_ot_ot > 0

    if form_kind_id == "0" || (!kanzai_flg && prop_flg)
      params[:item][:to_go] = ""
      params[:item][:participant_nums_inner] = ""
      params[:item][:participant_nums_outer] = ""
      params[:item][:check_30_over] = ""
      params[:item][:admin_memo] = ""
    end

    event_flg = false

    if kanzai_flg || has_ot_ot > 0
      params[:item][:allday] = nil
    else
      if !params[:item][:allday_radio_id].blank?
        if params[:init][:repeat_mode] == "1"
          params[:item][:allday] = params[:item][:allday_radio_id]
        elsif params[:init][:repeat_mode] == "2"
          params[:item][:allday] = params[:item][:repeat_allday_radio_id]
        end
      end
    end

    if prop_flg
      params[:item][:allday] = nil
    end

    params[:item][:guide_state] = '0'
    params[:item][:guide_place_id] = nil
    params[:item][:guide_place] = nil
    params[:item][:guide_ed_at] = '0'

    par_item_base, par_item_repeat = Gw::Schedule.separate_repeat_params params

    other_rent_flg = true
    other_admin_flg = true

    if !is_gw_admin
      ot_ot_ids.each{|o_props_id|
        flg = Gw::PropOtherRole.is_edit?(o_props_id)
        unless flg
          other_rent_flg = false
        end
        other_admin_flg =  Gw::PropOtherRole.is_admin?(o_props_id, cg.id) if other_admin_flg
      }
    end

    item.errors.add :"この設備","は照会のみ可能で予約は行えません。予約する場合は，設備の管理所属にお問い合わせください。" if !other_rent_flg

    err_num_st = item.errors.length
    case params[:init][:repeat_mode]
    when "1"

      st_at, ed_at = par_item_base[:st_at], par_item_base[:ed_at]
      %w(st ed).each {|fld|
        item.errors.add "#{fld}_at", 'が異常です' if !Gw.validates_datetime eval("#{fld}_at")
      }

      cond_shar = " and (extra_data is null or extra_data not like '%\"cancelled\":1%')" +
        " and schedule_id <> '#{item.id}'" +
        " and ( (gw_schedule_props.st_at <= '#{st_at}' and gw_schedule_props.ed_at > '#{st_at}' )" +
        " or (gw_schedule_props.st_at < '#{ed_at}' and gw_schedule_props.ed_at >= '#{ed_at}' )" +
        " or ('#{st_at}' <= gw_schedule_props.st_at and gw_schedule_props.st_at < '#{ed_at}') )"

      other_item_flg = true
      ot_ot_ids.each{|o_props_id|
        other_item = Gw::Schedule.find(:all, :joins=>'inner join gw_schedule_props on gw_schedules.id = gw_schedule_props.schedule_id',
          :conditions=>"prop_type='#{Gw::PropOther}' and prop_id='#{o_props_id}'" + cond_shar)
        if other_item.length > 0
          other_item_flg = false
        end
      }

      if item.errors.length == err_num_st
        d_st_at, d_ed_at = Gw.get_parsed_date(st_at), Gw.get_parsed_date(ed_at)

        if !prop_flg && !event_flg
          item.errors.add :ed_at, 'は、開始日時以降の日時を入力してください。' if d_st_at > d_ed_at
        else
          item.errors.add :ed_at, 'は、開始日時より後の日時を入力してください。' if d_st_at >= d_ed_at
        end

        competition_str = "終了日時は他の予定と競合しています。別の予定時間を入力してください。"
        item.errors.add :st_at, "、#{competition_str}（一般施設）" unless other_item_flg

      end

        if item.errors.length == err_num_st
          item.errors.add :st_at, 'と終了日時は一年以内でなければいけません。' if (d_ed_at - d_st_at) > 86400 * 365
          dates = (d_st_at.to_date..d_ed_at.to_date).to_a
        end

    when "2"

      st_date, ed_date = par_item_repeat[:st_date_at], par_item_repeat[:ed_date_at]
      st_time, ed_time = par_item_repeat[:st_time_at], par_item_repeat[:ed_time_at]
      %w(st_date ed_date st_time ed_time).each {|fld|
        item.errors.add "repeat_#{fld}_at", 'が異常です' if !Gw.validates_datetime eval(fld)
      }

      if item.errors.length == err_num_st
        d_st_date, d_ed_date = Gw.get_parsed_date(st_date), Gw.get_parsed_date(ed_date)
        d_st_time, d_ed_time = Gw.get_parsed_date(st_time), Gw.get_parsed_date(ed_time)
        item.errors.add :repeat_ed_date_at, 'は、開始日より後の日付を入力してください。' if d_st_date >= d_ed_date
        if !prop_flg
          item.errors.add :repeat_ed_time_at, 'は、開始時刻以降の時刻を入力してください。' if d_st_time > d_ed_time
        else
          item.errors.add :repeat_ed_time_at, 'は、開始時刻より後の時刻を入力してください。' if d_st_time >= d_ed_time
        end

      end

      if item.errors.length == err_num_st

        item.errors.add :repeat_st_time_at, 'と終了時刻は一年以内でなければいけません。' if (d_ed_date - d_st_date) > 86400 * 365

        if par_item_repeat[:class_id].blank?
          item.errors.add :repeat_class_id, 'を入力してください。'
        elsif par_item_repeat[:class_id].to_s == "3" && par_item_repeat[:weekday_ids].blank?
          item.errors.add :repeat_weekday_ids, 'を入力してください。'
        else

          dates = (d_st_date.to_date..d_ed_date.to_date).to_a
          case par_item_repeat[:class_id].to_s
          when "2"
            dates = dates.select{|x| !%w(1 2 3 4 5).index(x.wday.to_s).nil?}
          when "3"
            dates = dates.select{|x| !par_item_repeat[:weekday_ids].split(':').index(x.wday.to_s).nil?}
          end

          rent_date = st_date
          other_item_flg = true
          dateslen = dates.length

          prop_join = "inner join gw_schedule_props on gw_schedules.id = gw_schedule_props.schedule_id"

          dates.each {|rent_date|
            st_at = "#{rent_date} #{st_time}"
            ed_at = "#{rent_date} #{ed_time}"

            cond_results_shar = " and (extra_data is null or extra_data not like '%\"cancelled\":1%')" +
              " and (schedule_repeat_id <> '#{item.schedule_repeat_id}' or schedule_repeat_id is null)" +
              " and ( (gw_schedule_props.st_at <= '#{st_at}' and gw_schedule_props.ed_at > '#{st_at}' )" +
              " or (gw_schedule_props.st_at < '#{ed_at}' and gw_schedule_props.ed_at >= '#{ed_at}' )" +
              " or ('#{st_at}' <= gw_schedule_props.st_at and gw_schedule_props.st_at < '#{ed_at}') )"

            ot_ot_ids.each{|o_props_id|
              if other_item_flg
                other_item = Gw::Schedule.find(:all, :joins=>prop_join,
                  :conditions=>"prop_type='#{Gw::PropOther}' and prop_id='#{o_props_id}'" + cond_results_shar)
                if other_item.length > 0
                  other_item_flg = false
                end
              end
            }

            rent_time_st = Gw.get_parsed_date(rent_date.to_s + ' ' + st_time.to_s)
            rent_time_ed = Gw.get_parsed_date(rent_date.to_s + ' ' + ed_time.to_s)
            rent_time_st_s = rent_time_st.strftime("%Y-%m-%d 00:00:00")
            rent_time_ed_s = rent_time_ed.strftime("%Y-%m-%d 00:00:00")

          }

          competition_str = "終了日は他の予定と競合しています。また、繰り返し編集の場合、同じ予定でもすでに貸出・返却されている日時を入力することはできません。別の予定時間を入力してください。"
          item.errors.add :repeat_st_date_at, "、#{competition_str}（一般施設）" unless other_item_flg
          item.errors.add :repeat_st_date_at, "、終了日の間の期間、条件に当てはまる日は#{dates.length}日となります。繰り返し回数は2～55回のみ許されます。開始日、終了日、規則などを見直し、再度登録してください。" if dates.length < 2 || 55 < dates.length

        end
      end
    end

    %w(title is_public).each{|x| item.errors.add x, 'を入力してください。' if par_item_base[x].blank?}

    item.attributes = par_item_base.reject{|k,v|!%w(schedule_users_json schedule_props_json schedule_users public_groups public_groups_json schedule_props st_at_noprop ed_at_noprop event_week event_month event_word allday_radio_id allday_radio_id repeat_allday_radio_id form_kind_id).index(k).nil?}
    par_item_repeat.delete :allday_radio_id
    return false if item.errors.length != 0

    cnt = 0

    repeat_schedule_parent_id = []
    _props = JsonParser.new.parse(params[:item][:schedule_props_json])

    if _props.length > 0

      delete_props = Array.new

      case params[:init][:repeat_mode]
      when "1"
        delete_props << item.schedule_prop if !item.schedule_prop.blank?
        _props.each do |prop|
          cnt == 0 ? _item = item.dup : _item = Gw::Schedule.new
          Gw::Schedule.save_with_rels _item, params[:item], mode, prop, delete_props, {:restrict_trans=>1, :repeat_mode => params[:init][:repeat_mode]}
          _item.errors.each{|x| item.errors.add x[0], x[1]} if item != _item
          params[:item]['schedule_parent_id'] = _item.id if params[:item]['schedule_parent_id'].blank?
          cnt = cnt + 1
        end
      when "2"
        _props.each do |prop|
          date_for_time = Time.local(2010,4,1)
          par_item_repeat[:st_time_at] = Gw.datetime_merge(date_for_time, d_st_time)
          par_item_repeat[:ed_time_at] = Gw.datetime_merge(date_for_time, d_ed_time)
          item_org = item
          date_cnt = 0
          begin
            item_next = nil
            transaction do
              case mode
              when :update
                schedule_repeat_id = item.repeat.id
                cnt == 0 ? item_repeat = Gw::ScheduleRepeat.find(:first, :conditions=>"id=#{schedule_repeat_id}") : item_repeat = Gw::ScheduleRepeat.new
                item_repeat.update_attributes!(par_item_repeat)
                if cnt == 0
                  repeat_items = Gw::Schedule.new.find(:all, :conditions=>"schedule_repeat_id=#{schedule_repeat_id}")
                  repeat_items.each { |repeat_item|
                    if !repeat_item.is_actual?
                      delete_props << repeat_item.schedule_prop if !repeat_item.schedule_prop.blank?
                      repeat_item.destroy
                    end
                  }
                end
                dates.each {|d|
                  par_item_base['schedule_parent_id'] = repeat_schedule_parent_id[date_cnt]

                  item_dup = par_item_base.dup.merge({
                    :st_at => Gw.datetime_merge(d, d_st_time),
                    :ed_at => Gw.datetime_merge(d, d_ed_time),
                    :schedule_repeat_id => item_repeat.id,
                  })

                  _item = Gw::Schedule.new
                  ret_swr = Gw::Schedule.save_with_rels _item, item_dup, mode, prop, delete_props, {:restrict_trans=>1, :repeat_mode => params[:init][:repeat_mode]}
                  _item.errors.each{|x| item.errors.add x[0], x[1]} if item != _item
                  item_next = _item if item_next.nil?
                  raise if !ret_swr
                  if repeat_schedule_parent_id[date_cnt].blank?
                    repeat_schedule_parent_id[date_cnt] = _item.id
                  end

                  date_cnt = date_cnt + 1

                }

                item.update_attributes item_next.attributes
                item.id = item_next.id

              when :create

                item_repeat = Gw::ScheduleRepeat.new(par_item_repeat)
                item_repeat.save!

                dates.each {|d|
                  par_item_base['schedule_parent_id'] = repeat_schedule_parent_id[date_cnt]

                  item_dup = par_item_base.dup.merge({
                    :st_at => Gw.datetime_merge(d, d_st_time),
                    :ed_at => Gw.datetime_merge(d, d_ed_time),
                    :schedule_repeat_id => item_repeat.id,
                  })

                  _item = item.id.nil? ? item : Gw::Schedule.new
                  ret_swr = Gw::Schedule.save_with_rels _item, item_dup, mode, prop, [], {:restrict_trans=>1, :repeat_mode => params[:init][:repeat_mode]}
                  _item.errors.each{|x| item.errors.add x[0], x[1]} if item != _item

                  repeat_schedule_parent_id[date_cnt] = _item.id if repeat_schedule_parent_id[date_cnt].blank?

                  raise Gw::ARTransError if !ret_swr
                  date_cnt = date_cnt + 1

                }
              end
            end
          rescue => e

            case e.class.to_s
            when 'ActiveRecord::RecordInvalid', 'Gw::ARTransError'
              if item != item_org
                item_with_errors = item
                item = item_org
                item_with_errors.errors.each{|x| item.errors.add x[0], x[1]}
              end
            else
              raise e
            end
            return false
          end

          cnt = cnt + 1
        end
      else
        raise Gw::ApplicationError, "指定がおかしいです(repeat_mode=#{params[:init][:repeat_mode]})"
      end
    elsif _props.length == 0
      case params[:init][:repeat_mode]
      when "1"
        Gw::Schedule.save_with_rels item, params[:item], mode, nil, []
      when "2"
        date_for_time = Time.local(2010,4,1)
        par_item_repeat[:st_time_at] = Gw.datetime_merge(date_for_time, d_st_time)
        par_item_repeat[:ed_time_at] = Gw.datetime_merge(date_for_time, d_ed_time)

        item_org = item
        begin
          item_next = nil
          transaction do
            case mode
            when :update

              schedule_repeat_id = item.repeat.id
              item_repeat = Gw::ScheduleRepeat.find(:first, :conditions=>"id=#{schedule_repeat_id}")
              item_repeat.update_attributes!(par_item_repeat)

              Gw::Schedule.destroy_all("schedule_repeat_id=#{schedule_repeat_id}")
              dates.each {|d|
                item_dup = par_item_base.dup.merge({
                  :st_at => Gw.datetime_merge(d, d_st_time),
                  :ed_at => Gw.datetime_merge(d, d_ed_time),
                  :schedule_repeat_id => item_repeat.id,
                })

                _item = Gw::Schedule.new
                ret_swr = Gw::Schedule.save_with_rels _item, item_dup, mode, nil, [], {:restrict_trans=>1, :repeat_mode => params[:init][:repeat_mode]}
                _item.errors.each{|x| item.errors.add x[0], x[1]} if item != _item
                item_next = _item if item_next.nil?

                raise if !ret_swr
              }

              item.update_attributes item_next.attributes
              item.id = item_next.id

            when :create
              item_repeat = Gw::ScheduleRepeat.new(par_item_repeat)
              item_repeat.save!

              dates.each {|d|
                item_dup = par_item_base.dup.merge({
                  :st_at => Gw.datetime_merge(d, d_st_time),
                  :ed_at => Gw.datetime_merge(d, d_ed_time),
                  :schedule_repeat_id => item_repeat.id,
                })

                _item = item.id.nil? ? item : Gw::Schedule.new
                ret_swr = Gw::Schedule.save_with_rels _item, item_dup, mode, nil, [], {:restrict_trans=>1, :repeat_mode => params[:init][:repeat_mode]}
                _item.errors.each{|x| item.errors.add x[0], x[1]} if item != _item

                raise Gw::ARTransError if !ret_swr
              }
            end
          end
        rescue => e
          case e.class.to_s
          when 'ActiveRecord::RecordInvalid', 'Gw::ARTransError'
            if item != item_org
              item_with_errors = item
              item = item_org
              item_with_errors.errors.each{|x| item.errors.add x[0], x[1]}
            end
          else
            raise e
          end
          return false
        end

      else
        raise Gw::ApplicationError, "指定がおかしいです(repeat_mode=#{params[:init][:repeat_mode]})"
      end
    end

    return true
  end
end
