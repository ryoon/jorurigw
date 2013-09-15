class Gw::ScheduleProp < Gw::Database
  include System::Model::Base
  include Cms::Model::Base::Content
  belongs_to :schedule, :foreign_key => :schedule_id, :class_name => 'Gw::Schedule'
  belongs_to :prop, :polymorphic => true

  before_update :before_update_delete_view_cache
  after_save :after_save_delete_view_cache
  after_destroy :after_destroy_delete_view_cache

  def before_update_delete_view_cache
    self.delete_cache_action if self.prop_type != 'Gw::PropOther'
  end

  def after_save_delete_view_cache
    self.delete_cache_action if self.prop_type != 'Gw::PropOther'
  end

  def after_destroy_delete_view_cache
    self.delete_cache_action if self.prop_type != 'Gw::PropOther'
  end

  def delete_cache_action
    prop_id  = self.prop_id
    st_at = self.st_at
    ed_at = self.ed_at
    sp_mode = :prop
    s_genre = self.is_return_genre?
    today = Date.new(st_at.year, st_at.month, st_at.day)
    st_day = Date.new(st_at.year, st_at.month, st_at.day) - 6
    ed_day = Date.new(ed_at.year, ed_at.month, ed_at.day) + 6
    Gw::Model::Schedule.delete_user_prop_view_cache_action(st_day, ed_day, today, prop_id, sp_mode, s_genre)
  end

  def self.select_ownergroup_id_list(all = nil, extra_model_s = "")
    item = self.new
    join = "left join gw_schedules on gw_schedule_props.schedule_id = gw_schedules.id"
    cond = "prop_type='#{extra_model_s}' and owner_gid IS NOT NULL"
    items = item.find(:all, :group=>"owner_gname", :joins=>join, :conditions=>cond, :order=>"owner_gcode").map{|x| [x.schedule.owner_gname ,x.schedule.owner_gid]}
    owner_gname_list = [['すべて','0']] + items   if all=='all'
    owner_gname_list = items                      unless all=='all'
    return owner_gname_list
  end

  def self.select_prop_list(all=nil, genre=nil)
    item = Gw::PropOther
    items = item.find(:all, :order=>"sort_no")
    prop_list = [['すべて','0']] if all=='all'
    items.each do |item|
      prop_list << [item.name , item.id]
    end
    return prop_list
  end

  def self.select_st_at_list(all=nil, extra_model_s = "")
    item = self.new
    join = "left join gw_schedules on gw_schedule_props.schedule_id = gw_schedules.id"
    select = 'gw_schedule_props.*, gw_schedules.st_at, gw_schedules.ed_at, gw_schedules.creator_gcode'
    cond = "prop_type='#{extra_model_s}' and gw_schedules.st_at  IS NOT NULL"
    items = item.find(:all , :group=>"date(gw_schedules.st_at)", :joins=>join, :conditions=>cond, :order=>"gw_schedules.st_at DESC")
    st_at_list  = []
    st_at_list = [["当日以降", "0"], ["当日", "1"], ["当日以前", "2"], ["すべて", "3"]] if all == 'all'
    st_at_list = [["当日以降", "0"]] if all == 'dynasty'
    items.each do |item|
      st_at_list << [item.schedule.st_at.strftime("%Y-%m-%d") , item.schedule.st_at.strftime("%Y-%m-%d")]
    end
    return st_at_list
  end

  def self.prop_params_set(_params)

    keys = 'cls:s_genre:s_prop_name:s_subscriber:page:sort_keys:history:s_owner_gid:s_prop_state:s_st_at:s_year:s_month:s_day:results'
    keys = keys.split(':')
    ret = ""
    keys.each_with_index do |col, idx|
      unless _params[col.to_sym].blank?
        ret += "&" unless ret.blank?
        ret += "#{col}=#{_params[col.to_sym]}"
      end
    end
    ret = '?' + ret unless ret.blank?
    return ret
  end

  def self.is_admin?(genre, extra_flag, options={})
    _ef = nz(extra_flag, 'other')
    return true if _ef == 'other'
    return false
  end

  def search_where(params)
    ret_a = []
    params.each do |n, v|
      next if v.to_s == ''
      case n
      when 's_genre'
        prop_type = "Gw::Prop#{v.capitalize}"
        ret_a.push "prop_type='#{prop_type}'"
      end
    end if params.size != 0
    return ret_a.collect{|x| "(#{x})"}.join(" and ")
  end

  def self.get_genres
    ':other/一般施設'.split(':').map{|x| x.split('/')}
  end

  def self.get_genre_select(options={})
    key_prefix = options[:key_prefix].nil? ? '' : options[:key_prefix]
    [
      [ '一般施設', "#{key_prefix}other:other" ]
    ]
  end

  def prop_stat_s
    stats = [[0,'<span style="color:#FF0000;">未承認</span>'], [1, '<span style="color:#2E49B4;">承認済</span>'], [2, '<span style="color:#FF3F38;">貸出中</span>'], [3, '<span style="color:#CFD0D2;">返却済</span>'], [4, '<span style="color:#860000;">集計済</span>'], [5, '<span style="color:#FFC5FF;">請求済</span>'], [900, '<span style="color:#008100;">キャンセル</span>'], [nil, '(承認不要)']]
    stat = stats.assoc(prop_stat)
    return stat[1]
  end

  def prop_stat_s2
    stats = [[0,'<span style="color:#FF0000;">未承認</span>'], [1, '承認済'], [2, '貸出中'], [3, '返却済'], [4, '集計済'], [5, '請求済'], [900, 'キャンセル'], [nil, '(承認不要)']]
    stat = stats.assoc(prop_stat)
    return stat[1]
  end

  def csv_prop_stat_s
    stats = [[0,'未承認'], [1, '承認済'], [2, '貸出中'], [3, '返却済'], [4, '集計済'], [5, '請求済'], [900, 'キャンセル'], [nil, '(承認不要)']]
    stat = stats.assoc(self.prop_stat)
    return stat[1]
  end

  def self.confirmed_s(confirmed)
    confirmed.nil? ? '(承認不要)' : confirmed ? '承認済' : '<span style="color:red;">未承認</span>'
  end

  def self.prop_conv(conv, val)
    ret = case conv
    when :genre_to_mdl
      "Gw::Prop#{val.camelize}"
    when :mdl_to_genre
      val.sub(/^Gw::Prop/, '').underscore
    end
    return ret
  end

  def owner_s(options={})
    genre = prop.class.name.split('::').last.gsub(/^Prop/, '').downcase
    owner_class = prop.extra_flag
    case genre
    when 'other'
      prop.gname
    else
      prop_classes_raw[genre][owner_class]
    end
  end

  def get_extra_data
    _extra_data = nz(extra_data)
    _extra_data.blank? ? {} : JsonParser.new.parse(_extra_data) rescue {:error=>1}
  end

  def set_extra_data(set_data, options={})
    set_data_h = set_data.is_a?(Hash) ? set_data : JsonParser.new.parse(s_from)
    if nz(options[:override],0) != 0
      _extra_data = set_data_h
    else
      _extra_data = get_extra_data
      _extra_data.merge! set_data_h
    end
    _extra_data.delete_if{|k,v|v.nil?}
    self.extra_data = _extra_data.blank? ? nil : _extra_data.to_json
  end

  def confirmed?
    nil
  end

  def confirm
    if confirmed?
      set_extra_data({'confirmed' => nil})
      self.confirmed_uid = nil
      self.confirmed_gid = nil
      self.confirmed_at = nil
      return :unconfirm_done
    else
      set_extra_data({'confirmed' => 1})
      self.confirmed_uid = Site.user.id
      self.confirmed_gid = Site.user_group.id
      self.confirmed_at = Time.now

        _prop = Gw::ScheduleProp.find_by_id(self.id)
        system_settings = Gw::NameValue.get('yaml', nil, "gw_schedule_props_settings_system_default")
        if !nf(system_settings[:add_memo_send_to_announce]).blank?
          add_memo_send_to = _prop.schedule.creator_uid
          creator = Gw::Model::Schedule.get_user(add_memo_send_to)
          ret = Gw.add_memo(add_memo_send_to, '設備予約が承認されました。', %Q(<a href="/gw/schedules/#{_prop.schedule.id}/show_one">予約情報の確認</a>),{:is_system => 1}) unless creator.blank?
        end

      return :confirm_done
    end
  end

  def rented?
    return nil
  end

  def rent
    set_extra_data({'rented' => 1})
    user = Site.user
    self.rented_uid = user.id
    self.rented_gid = Site.user_group.id
    self.rented_at  = Time.now
    return :rent_done
  end

  def returned?
    return nil
  end

  def return
    return :return_undone if !rented?
    set_extra_data({'returned' => 1})
    user = Site.user
    self.returned_uid = user.id
    self.returned_gid = Site.user_group.id
    self.returned_at  = Time.now
    return :return_done
  end

  def cancelled?
    nz(get_extra_data['cancelled'],0) != 0
  end

  def cancel
    if cancelled?
      self.cancelled_at  = nil
      set_extra_data({'cancelled' => nil})
      return :uncancel_done
    else
      self.cancelled_at  = Time.now
      set_extra_data({'cancelled' => 1})
      return :cancel_done
    end
  end

  def prop_stat
    case self.prop_type
    when "Gw::PropOther"
      ret = self.cancelled? ? 900 :
        self.returned? ? 3 :
        self.rented? ? 2 : nil
      return ret
    else
      nil
    end
  end

  def self.get_prop_state_str(state_no = nil)
    return '' if state_no.blank?
    if state_no == 900
      return 'キャンセル'
    elsif state_no == 5
      return '請求'
    elsif state_no == 4
      return '集計'
    elsif state_no == 3
      return '返却'
    elsif state_no == 2
      return '貸出'
    elsif state_no == 1
      return '承認'
    end
  end

  def prop_stat_category_id
    case self.prop_type
    when "Gw::PropOther"
      ret = self.cancelled? ? 900 :
        self.returned? ? 3 :
        self.rented? ? 2 : nil
      return ret
    else
      nil
    end
  end

  def _name
    self.prop.name
  end

  alias :_prop_name :_name

  def _owner
    self.schedule.owner_uname
  end

  def _subscriber
    self.schedule.owner_gname
  end

  def _prop_stat
    self.prop_stat_s
  end

  def is_kanzai?
    if self.prop_type == "Gw::PropOther"
      return 3
    else
      return 4
    end
  end

  def is_return_genre?
    if self.prop_type == "Gw::PropOther"
      return "other"
    end
  end

  def self.is_prop_edit?(prop_id, genre, options = {})
    if options.key?(:is_gw_admin)
      is_gw_admin = options[:is_gw_admin]
    else
      is_gw_admin = Gw.is_admin_admin?
    end

    flg = true
    prop = []

    if options[:prop].blank?
      case genre
      when 'other'
        prop = Gw::PropOther.find(prop_id)
      else

      end
    else
      prop = options[:prop]
    end

    unless prop.blank?
      if genre == 'other' && !is_gw_admin
        flg = Gw::PropOtherRole.is_edit?(prop_id) && (prop.reserved_state == 1 || prop.delete_state == 0)
      end
      if prop.reserved_state == 0 || prop.delete_state == 1
        flg = false
      end
    else
      flg = false
    end

    return flg
  end

  def self.getajax(_params, _options={})
    begin
      params = HashWithIndifferentAccess.new(_params)
      options = HashWithIndifferentAccess.new(_options)
      genre_raw = params['s_genre']
      genre, cls, be = genre_raw.split ':'
      st_at = Gw.to_time(params['st_at']) rescue nil
      ed_at = Gw.to_time(params['ed_at']) rescue nil
      case genre
      when nil
        item = {:errors=>'施設指定が異常です'}
      when 'other'
        model_name = "Gw::Prop#{genre.capitalize}"
        model = eval(model_name)
        if st_at.nil? || ed_at.nil? || st_at >= ed_at
          item = {:errors=>'日付が異常です'}
        else
          @index_order = 'extra_flag, sort_no, gid, name'
          cond_props_within_terms = "SELECT distinct prop_id FROM gw_schedules"
          cond_props_within_terms += " left join gw_schedule_props on gw_schedules.id =  gw_schedule_props.schedule_id"
          cond_props_within_terms += " where"
          cond_props_within_terms += " gw_schedules.ed_at >= '#{Gw.datetime_str(st_at)}'"
          cond_props_within_terms += " and gw_schedules.st_at < '#{Gw.datetime_str(ed_at)}'"
          cond_props_within_terms += " and prop_type = '#{model_name}'"
          cond_props_within_terms += " and (gw_schedule_props.extra_data is null or gw_schedule_props.extra_data not like '%\"cancelled\":1%')" # キャンセルを条件に加えるSQL文
          cond_props_within_terms += " order by prop_id"
          cond = "coalesce(extra_flag,'other')='#{cls}' and piwt.prop_id is null"
          cond += " and gw_prop_#{genre}s.delete_state = 0 and gw_prop_#{genre}s.reserved_state = 1"

          joins = "left join (#{cond_props_within_terms}) piwt on gw_prop_#{genre}s.id = piwt.prop_id"
          if genre == "other"

            item = model.blank? ? [] : model.find(:all, :joins=>joins, :conditions=>cond, :order=>"type_id, gid, sort_no, name").select{|x|
                Gw::PropOtherRole.is_edit?(x.id)
              }.collect{|x| [genre, x.id, "(" + System::Group.find(x.gid).code.to_s + ")" + x.name.to_s, x.gname]}
          else
            item = model.blank? ? [] : model.find(:all, :joins=>joins, :conditions=>cond, :order=>@index_order).collect{|x| [genre, x.id, x.name, x.gname]}
          end
          item = {:errors=>'該当する候補がありません'} if item.blank?
        end
      end
      return item
    rescue
      return {:errors=>'不明なエラーが発生しました'}
    end
  end
end
