class Gw::Schedule < Gw::Database
  include System::Model::Base
  include Cms::Model::Base::Content
  validates_presence_of :title, :is_public
  gw_validates_datetime :st_at
  gw_validates_datetime :ed_at
  validates_each :st_at do |record, attr, value|
    d_st = Gw.get_parsed_date(record.st_at)
    d_ed = Gw.get_parsed_date(record.ed_at)
    record.errors.add attr, 'と終了日時の前後関係が異常です。' if d_st > d_ed
  end
  has_many :schedule_props, :foreign_key => :schedule_id, :class_name => 'Gw::ScheduleProp', :dependent=>:destroy
  has_one :schedule_prop, :foreign_key => :schedule_id, :class_name => 'Gw::ScheduleProp', :dependent=>:destroy # 現在のところ、施設テーブルはスケジュールテーブルと1対1
  has_many :schedule_users, :foreign_key => :schedule_id, :class_name => 'Gw::ScheduleUser', :dependent=>:destroy
  belongs_to :repeat, :foreign_key => :schedule_repeat_id, :class_name => 'Gw::ScheduleRepeat'
  belongs_to :parent, :foreign_key => :schedule_parent_id, :class_name => 'Gw::Schedule'
  has_many :child, :foreign_key => :schedule_parent_id, :class_name => 'Gw::Schedule'
  has_many :public_roles, :foreign_key => :schedule_id, :class_name => 'Gw::SchedulePublicRole', :dependent=>:destroy

  def self.joined_self(options={})
    op = options.dup
    op[:order] = 'st_at, ed_at' if op[:order].blank?
    op[:joins] = 'left join gw_schedule_users on gw_schedules.id = gw_schedule_users.schedule_id'
    op[:select] = 'gw_schedules.*' if op[:select].blank?
    find(:all, op)
  end

  def self.save_with_rels(item, par_item, mode, prop, delete_props = Array.new, options = {})

    repeat_mode = nz(options[:repeat_mode], 1).to_i

    di = par_item.dup
    di.delete :public_groups
    _public_groups = JsonParser.new.parse(par_item[:public_groups_json])
    di.delete :public_groups_json

    di.delete :schedule_users
    _users = JsonParser.new.parse(par_item[:schedule_users_json])
    di.delete :schedule_users_json

    kind_id = par_item[:form_kind_id]
    di.delete :form_kind_id

    di = di.merge ret_updator

    if mode == :create || (mode == :update && !options[:restrict_trans].blank?)
      if di[:creator_uid].blank?
        cu = Site.user
        di[:creator_uid] = cu.id
        di[:creator_ucode] = cu.code
        di[:creator_uname] = cu.name
        cg = cu.groups[0]
        di[:creator_gid] = cg.id
        di[:creator_gcode] = cg.code
        di[:creator_gname] = cg.name
      else
        creator_group = Gw::Model::Schedule.get_group(:gid => di[:creator_gid])
        di[:creator_gid] = creator_group.id
        di[:creator_gcode] = creator_group.code
        di[:creator_gname] = creator_group.name
      end

      ou = Gw::Model::Schedule.get_user(par_item[:owner_uid]) rescue Site.user
      di[:owner_uid] = ou.id
      di[:owner_ucode] = ou.code
      di[:owner_uname] = ou.name
      og = ou.groups[0]
      di[:owner_gid] = og.id
      di[:owner_gcode] = og.code
      di[:owner_gname] = og.name
    end
    if mode == :update
      ou = Gw::Model::Schedule.get_user(par_item[:owner_uid]) rescue Site.user
      di[:owner_uid] = ou.id
      di[:owner_ucode] = ou.code
      di[:owner_uname] = ou.name
      og = ou.groups[0]
      di[:owner_gid] = og.id
      di[:owner_gcode] = og.code
      di[:owner_gname] = og.name

      if di[:created_at].blank?
        created_at = Time.now
      else
        created_at = di[:created_at].to_datetime
      end
      di[:created_at] = created_at
    end
    if mode == :create
      di.delete :created_at
    end

    di.delete :schedule_props
    di.delete :schedule_props_json
    di.delete :allday_radio_id
    di.delete :repeat_allday_radio_id

    di[:st_at] = Gw.date_common(Gw.get_parsed_date(par_item[:st_at])) rescue nil
    di[:ed_at] = di[:st_at].blank? ? nil :
      par_item[:ed_at].blank? ? Gw.date_common(Gw.get_parsed_date(di[:st_at]) + 3600) :
      Gw.date_common(Gw.get_parsed_date(par_item[:ed_at])) rescue nil

    item.st_at = Gw.date_common(Gw.get_parsed_date(par_item[:st_at])) rescue nil
    item.ed_at = Gw.date_common(Gw.get_parsed_date(par_item[:ed_at])) rescue nil

    proc_core = lambda{

      if mode == :update
        return false if !item.update_attributes(di)
        Gw::ScheduleUser.destroy_all("schedule_id=#{item.id}")
        Gw::ScheduleProp.destroy_all("schedule_id=#{item.id}")
      else
        return false if !item.update_attributes(di)
      end

      if !prop.blank?
        if par_item[:schedule_parent_id].blank?
          di[:schedule_parent_id] = item.id
          item.update_attributes(di)
        end

        item_sub = Gw::ScheduleProp.new()
        item_sub.schedule_id = item.id
        item_sub.st_at = item.st_at
        item_sub.ed_at = item.ed_at

        item_sub.prop_type = "Gw::Prop#{prop[0].capitalize}"
        item_sub.prop_id = prop[1]

        return false if !item_sub.save
      end

      _users.each do |user|
        item_sub = Gw::ScheduleUser.new()
        item_sub.schedule_id = item.id
        item_sub.st_at = item.st_at
        item_sub.ed_at = item.ed_at
        item_sub.class_id = user[0].to_i
        item_sub.uid = user[1]
        return false if !item_sub.save
      end

      Gw::SchedulePublicRole.destroy_all("schedule_id=#{item.id}") if mode == :update
      if ( prop.blank? || (!prop.blank? && prop[0] == "other") ) && par_item[:is_public] == '2'
        _public_groups.each do |_public_group|
          item_public_role = Gw::SchedulePublicRole.new()
          item_public_role.schedule_id = item.id
          item_public_role.class_id = 2
          item_public_role.uid = _public_group[1]
          return false if !item_public_role.save
        end
      end
      return true
    }

    if !options[:restrict_trans].blank?
      return proc_core.call
    else
      begin
        transaction() do
          raise Gw::ARTransError if !proc_core.call
        end
        return true
      rescue => e
        case e.class.to_s
        when 'ActiveRecord::RecordInvalid', 'Gw::ARTransError'
        else
          raise e
        end
        return false
      end
    end
  end

  def self.separate_repeat_params(params)
    item_main = HashWithIndifferentAccess.new
    item_repeat = HashWithIndifferentAccess.new
    params[:item].each_key{|k|
      if /^repeat_(.+)/ =~ k.to_s
        item_repeat[$1] = params[:item][k]
      else
        item_main[k] = params[:item][k]
      end
    }
    return [item_main, item_repeat]
  end

  def repeated?
    !self.schedule_repeat_id.blank?
  end

  def  get_repeat_items
    return Array.new if !self.repeated?
    return self.find(:all, :conditions=>"schedule_repeat_id='#{self.schedule_repeat_id}'", :order=>"st_at, id")
  end

  def  get_parent_items
    if self.schedule_parent_id.blank?
      return Array.new
    else
      return self.find(:all, :conditions=>"schedule_parent_id='#{self.schedule_parent_id}'", :order=>"st_at, id")
    end
  end


  def  get_repeat_and_parent_items
    items = Array.new
    items << self

    parent_items = self.get_parent_items
    parent_items.each do | parent_item |
      items += parent_item.get_repeat_items
    end

    repeat_items = self.get_repeat_items
    repeat_items.each do | repeat_item |
      items += repeat_item.get_parent_items
    end

    return items.uniq
  end

  def  get_parent_props_items
    parent_items = self.get_parent_items
    if parent_items.blank?
      return Array.new
    else
      props_items = Array.new
      parent_items.each do |parent_item|
        props_items << parent_item.schedule_prop
      end
      return props_items
    end
  end

  def repeat_item_first?
    return true if !self.repeated?

    repeat_id = self.schedule_repeat_id
    sche = Gw::Schedule
    item = sche.find(:first, :conditions=>"schedule_repeat_id='#{repeat_id}'", :order=>"st_at")

    if item.id == self.id
      return true
    else
      return false
    end
  end

  def repeat_end_str
    return "" if !self.repeated?

    repeat_id = self.schedule_repeat_id
    sche = Gw::Schedule
    item = sche.find(:first, :conditions=>"schedule_repeat_id='#{repeat_id}'", :order=>"st_at DESC")

    return " ～" + item.ed_at.day.to_s + "日"
  end

  def stepped_over?
    st_date = self.st_at.to_date
    ed_data = self.ed_at.to_date

    if st_date + 1 <= ed_data
      return true
    else
      return false
    end
  end

  def stepped_st_date_today?(date = Date.today)
    st_date = self.st_at.to_date
    return st_date == date
  end

  def schedule_approval?
    event_auth = {:approved => false, :opened => false}
    return event_auth
  end

  def search(params)
    params.each do |n, v|
      next if v.to_s == ''
      end if params.size != 0
    return self
  end

  def is_actual?
    return nil
  end

  def ret_repeated?
    repeat_id = self.schedule_repeat_id
    item = Gw::ScheduleProp.new
    ret = item.find(:all, :select=>'gw_schedule_props.*, gw_schedules.st_at, gw_schedules.ed_at, gw_schedules.creator_gcode',
      :joins=> "left join gw_schedules on gw_schedule_props.schedule_id = gw_schedules.id",
      :conditions=>"schedule_repeat_id='#{repeat_id}'")

    flg = true
    ret = ret.select{|x|
      flg = false if x.prop_stat > 1
    }
    return flg
  end

  def self.is_schedule_pref_admin?(uid = Site.user.id)
    System::Model::Role.get(1,uid,'schedule_pref','schedule_pref_admin')
  end

  def is_schedule_pref_admin_users?
    pref_admin = Gw::NameValue.get_cache('yaml', nil, "gw_schedule_pref_admin_default")
    pref_admin_code = nf(pref_admin["pref_admin_code"])
    unless pref_admin_code.blank?
      self.schedule_users.each do |user|
        sys_user = System::User.get(user.uid)
        unless sys_user.blank?
          ucode = nz(System::User.get(user.uid).code, "0")
          if pref_admin_code == ucode
            return true
          end
        end
      end
    end
    return false
  end

  def is_public_closed_auth?(is_gw_admin = Gw.is_admin_admin?, options = {})

    return false if is_gw_admin
    uids = []
    gids = []

    prop = self.schedule_prop
    is_kanzai = 4
    is_other_my = false
    if !prop.blank? && !prop.prop.blank?
      is_kanzai = prop.is_kanzai?
      if is_kanzai == 3 && Gw::PropOtherRole.is_admin?(prop.prop.id)
        is_other_my = true
      end
    end

    uids = [self.creator_uid]
    self.schedule_users.each{|x|
      if x.class_id == 1
        uids = uids + [x.uid]
        unless x.user.blank?
          x.user.user_groups.each{|z|
            gids = gids + [z.group_id] unless x.user.nil?
          }
        end
      elsif x.class_id == 2
        unless x.group.blank?
          x.group.user_group.each{|z|
            uids = uids + [z.user_id]
            gids = gids + [z.group_id]
          }
        end
      end
    }

    self.public_roles.each do |public_role|
      if public_role.class_id == 2
        role_group = public_role.group
        unless role_group.blank?
          if !role_group.blank? && role_group.level_no == 2
            role_group.children.each do |children|
              gids << children.id
            end
          else
            gids << role_group.id
          end
        end
      end
    end

    uids = uids.sort.uniq
    gids = gids.sort.uniq

    common_condition =  ((self.is_public == 2 && self.creator_uid.to_i != Site.user.id && (gids.index(Site.user_group.id).nil? && gids.index(Site.user_group.parent_id).nil?)) ||
        (self.is_public == 3 && uids.index(Site.user.id).nil?))

    if (is_kanzai == 1 || is_kanzai == 2) &&
        common_condition && !is_gw_admin
      return true
    elsif is_kanzai == 3 && !is_other_my && common_condition && !is_gw_admin
      return true
    elsif is_kanzai == 4 && common_condition && !is_gw_admin
      return true
    end

    return false
  end

  def self.ret_updator
    items = {}
    uu = Site.user
    items[:updater_uid] = uu.id
    items[:updater_ucode] = uu.code
    items[:updater_uname] = uu.name
    ug = uu.groups[0]
    items[:updater_gid] = ug.id
    items[:updater_gcode] = ug.code
    items[:updater_gname] = ug.name
    return items
  end

  def is_schedule_user?(uid = Site.user.id, gid = Site.user_group.id)
    ret = self.schedule_users.select{|x| ( x.class_id == 1 && x.uid == uid ) || ( x.class_id == 2 && x.uid == gid ) }
    if ret.size > 0
      return true
    else
      return false
    end
  end

  def is_prop_type?
    props = self.get_prop_items
    return 0 if props.length == 0
    type = 1
    props.each { |prop|
      if prop.prop_type == "Gw::PropOther"
        type = 1 if type <= 1
      end
    }
    return type
  end

  def get_prop_items
    props = []
    if !self.schedule_parent_id.blank?
      if self.parent.blank?
        item_parents = Gw::Schedule.find(:all, :conditions=>"schedule_parent_id = #{self.schedule_parent_id}", :order => "id")
      else
        item_parents = self.parent.child
      end
      item_parents.each do |item_parent|
        item_parent.schedule_props.each do |prop|
          props << prop if !prop.prop.blank? && prop.prop.delete_state == 0
        end
      end
    else
      self.schedule_props.each do |prop|
        props << prop if !prop.prop.blank? && prop.prop.delete_state == 0
      end
    end
    return props
  end

  def get_propnames
    props = self.get_prop_items
    names = ""
    len = props.length
    if len > 0
      is_user = self.is_schedule_user? # 参加者
      props.each_with_index { |prop, i|
        name = ""
        get_prop = prop.prop
        if !prop.prop.blank? && (prop.prop_type != "Gw::PropOther" || (prop.prop_type == "Gw::PropOther" && (get_prop.is_admin_or_editor_or_reader? || is_user) ) )
          if get_prop.delete_state != 1
            name = get_prop.name
          end
        end
        names += name
        names += "," if i != len - 1 && !name.blank?
      }
    end
    return names
  end

  def get_usernames
    _names = Array.new
    names = ""
    len = self.schedule_users.length
    if len > 0
      self.schedule_users.each_with_index do |user, i|
        begin
          case user.class_id
          when 0
          when 1
            _user = user.user
            _names << user.user.name if !_user.blank? && _user.state == 'enabled'
          when 2
            _group = user.group
            _names << user.group.name if !_group.blank? && _group.state == 'enabled'
          end
        rescue
        end
      end
    end
    names = Gw.join(_names, ',')
    return names
  end

  def self.schedule_linked_time_save(item, st_at, ed_at)

    item.schedule_props.each do |item_prop|
      item_prop.st_at = st_at
      item_prop.ed_at = ed_at
      item_prop.save!
    end

    item.schedule_users.each do |item_user|
      item_user.st_at = st_at
      item_user.ed_at = ed_at
      item_user.save!
    end

  end

  def self.save_with_rels_part(item, params)

    _params = params[:item].dup
    if !params[:item][:st_at].blank?
      st_at, ed_at = Gw.get_parsed_date(params[:item][:st_at]), Gw.get_parsed_date(params[:item][:ed_at])
      d_st_at, d_ed_at = Gw.get_parsed_date(st_at), Gw.get_parsed_date(ed_at)
      item.errors.add :st_at, 'と終了日時の前後関係が不正です。'  if st_at > ed_at
      item.errors.add :st_at, 'と終了日時は１年以内でなければいけません。' if (d_ed_at - d_st_at) > 86400 * 365
    end

    if !params[:item][:allday_radio_id].blank?
      if params[:init][:repeat_mode] == "1"
        _params[:allday] = params[:item][:allday_radio_id]
      elsif params[:init][:repeat_mode] == "2"
        _params[:allday] = params[:item][:repeat_allday_radio_id]
      end
    else
      _params[:allday] = nil
    end

    if item.errors.length == 0

      if !params[:item][:st_at].blank?
        _params[:st_at] = st_at.strftime("%Y-%m-%d %H:%M:%S")
        _params[:ed_at] = ed_at.strftime("%Y-%m-%d %H:%M:%S")
        schedule_linked_time_save(item, st_at, ed_at)
      end

      if !params[:item][:allday_radio_id].blank?
        _params[:allday] = _params[:allday_radio_id]
      end

      _params = _params.merge ret_updator
      _params[:updated_at] = Time.now.strftime("%Y-%m-%d %H:%M:%S")

      _params[:admin_memo] = params[:item][:admin_memo]

      if !params[:item][:schedule_users_json].blank?
        _users = JsonParser.new.parse(params[:item][:schedule_users_json])
        Gw::ScheduleUser.destroy_all("schedule_id=#{item.id}")
        _users.each do |user|
          item_sub = Gw::ScheduleUser.new()
          item_sub.schedule_id = item.id
          item_sub.st_at = st_at
          item_sub.ed_at = ed_at
          item_sub.class_id = user[0].to_i
          item_sub.uid = user[1]
          return false if !item_sub.save
        end
      end

      _params = _params.reject{|k,v|!%w(ed_at(1i) ed_at(2i) ed_at(3i) ed_at(4i) ed_at(5i) st_at(1i) st_at(2i) st_at(3i) st_at(4i) st_at(5i) schedule_users_json schedule_users allday_radio_id allday_radio_id form_kind_id).index(k).nil?}

      item.update_attributes(_params)
      return true

    else
      return false
    end

  end

  def self.ret_auth_hash(auth = {})
    if !auth.key?(:is_gw_admin)
      auth[:is_gw_admin] = Gw.is_admin_admin?
    end
    return auth
  end

  def schedule_event_existence
     return false
  end

  def get_propdata_and_repeat_id
    childs = self.child
    ret = Array.new

    if !childs.blank?
      childs.each do |child|
        if !child.schedule_repeat_id.blank?
          prop = child.schedule_prop
          ret << [ prop.is_return_genre?, prop.prop_id, child.schedule_repeat_id ]
        end
      end
    end

    if ret.empty?
      return nil
    else
      return ret
    end
  end

  def self.get_origin_repeat_id(prop, repeat_datas)
    repeat_id = nil
    repeat_datas.each do |repeat_data|
      if repeat_data[0] == prop[0] && repeat_data[1].to_i == prop[1].to_i
        repeat_id = repeat_data[2]
      end
    end
    return repeat_id
  end

  def get_edit_delete_level(auth = {})
    # auth_level[:edit_level]
    #    1：編集可能
    #    2：開始日時、終了日時、終日、管理者メモのみ編集可能
    #    3：参加者を編集可能
    #    4：管理者メモのみ編集可能
    #    100：編集不可
    # auth_level[:delete_level]
    #    1：削除可能
    #    100：削除不可

    auth = Gw::Schedule.ret_auth_hash(auth)
    auth_level = {:edit_level => 100, :delete_level => 100}

    if auth[:is_gw_admin]
      auth_level[:edit_level] = 1
      auth_level[:delete_level] = 1
      return auth_level
    end

    uid = Site.user.id
    gid = Site.user_group.id

    event_auth = self.schedule_approval?
    event_state = '承認'
    event_state = '公開' if event_auth[:opened]

    creator = self.creator_uid == uid
    creator_group = self.creator_gid == gid

    schedule_uids = self.schedule_users.select{|x|x.class_id==1}.collect{|x| x.uid}
    participant = !schedule_uids.index(uid).nil?

    prop = self.schedule_prop
    if !prop.blank?
      prop_state = nz(prop.prop_stat, 0).to_i
    else
      prop_state = 0
    end

    if !prop.blank? && prop.prop_type == "Gw::PropOther"
        if Gw::PropOtherRole.is_admin?(prop.prop.id, gid)
          auth_level[:edit_level] = 1
          auth_level[:delete_level] = 1
        end
        if creator || participant
          auth_level[:edit_level] = 1
          auth_level[:delete_level] = 1
        end
    end

    if prop.blank?
        if creator || participant
          auth_level[:edit_level] = 1
          auth_level[:delete_level] = 1
        end
    end

    return auth_level
  end

  def self.schedule_tabbox_struct(tab_captions, selected_tab_idx=nil, radio=nil, options={})
    tab_current_cls_s = ' ' + Gw.trim(nz(options[:tab_current_cls_s], 'current'))
    id_prefix = Gw.trim(nz(options[:id_prefix], nz(options[:name_prefix], '')))
    id_prefix = "[#{id_prefix}]" if !id_prefix.blank?
    tabs = <<-"EOL"
<div class="tabBox">
<table class="tabtable">
<tbody>
<tr>
<td id="spaceLeft" class="spaceLeft"></td>
EOL
    tab_idx = 0
    tab_captions.each_with_index{|x, idx|
      tab_idx += 1
      _name = "tabBox#{id_prefix}[#{tab_idx}]"
      _id = Gw.idize(_name)
      tabs += %Q(<td class="tab#{selected_tab_idx - 1 == idx ? tab_current_cls_s : nil}" id="#{_id}">#{x}</td>) +
        (tab_captions.length - 1 == idx ? '' : '<td id="spaceCenter" class="spaceCenter"></td>')
    }
    tabs += <<-"EOL"
<td id="spaceRight" class="spaceRight">#{radio}</td>
</tr>
</tbody>
</table>
</div><!--tabBox-->
EOL
    return tabs
  end

  def public_groups_display
    ret = Array.new
    self.public_roles.each do |public_role|
      if public_role.class_id == 2
        if public_role.uid == 0
          ret << "制限なし"
        else
          group = System::GroupHistory.find_by_id(public_role.uid)
          if !group.blank?
            if group.state == "disabled"
              ret << "<span class=\"required\">#{group.name}</span>"
            else
              ret << [group.name]
            end
          else
            ret << "<span class=\"required\">削除所属 gid=#{public_role.uid}</span>"
          end
        end
      end
    end
    return ret
  end

  def self.is_public_select
    is_public_items = [['公開（誰でも閲覧可）', 1],['所属内（参加者の所属および公開所属）', 2],['非公開（参加者のみ）',3]]
    return is_public_items
  end

  def self.is_public_show(is_public)
    is_public_items = [[1,'公開（誰でも閲覧可）'],[2,'所属内（参加者の所属および公開所属）'],[3,'非公開（参加者のみ）']]
    show = is_public_items.assoc(is_public)
    if show.blank?
      return nil
    else
      return show[1]
    end
  end

  def self.schedule_show_support(schedules)
    schedule_parent_ids = Array.new
    items = Array.new
    schedules.each { |sche|
      if sche.schedule_parent_id.blank?
        items << sche
      else
        if schedule_parent_ids.blank? || schedule_parent_ids.index(sche.schedule_parent_id).blank?
          schedule_parent_ids << sche.schedule_parent_id
          items << sche
        end
      end
    }
    return items
  end

end
