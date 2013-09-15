class System::GroupTemporary < ActiveRecord::Base
  include System::Model::Base
  include System::Model::Tree
  include System::Model::Base::Config

  belongs_to :status,     :foreign_key => :state,     :class_name => 'System::Base::Status'
  belongs_to :parent,     :foreign_key => :parent_id, :class_name => 'System::GroupTemporary'
  has_many   :user_group, :foreign_key => :group_id,  :class_name => 'System::UsersGroupTemporary'
  has_and_belongs_to_many :users, :class_name => 'System::UserTemporary',
    :join_table => 'system_users_group_temporaries', :order => 'job_order,system_user_temporaries.name_en'

  validates_presence_of :state,:code,:name,:start_at
  validates_uniqueness_of :code ,:scope => [:parent_id]


  validates_each :end_at do |record, attr, value|
    record.errors.add attr, 'には、適用開始日より後の日付を入力してください'  if value.blank? ? false : (value <= record.start_at)
  end
  validates_each :code do |record, attr, value|
    record.errors.add attr, "は、#{Site.code_length(record.level_no)}桁で入力してください" if value.blank? ? false : (value.length != Site.code_length(record.level_no))
  end

  require 'date'

  def ou_name
    code.to_s + name
  end

  def display_name
    name
  end

  def self.usable?(g_id,day=nil)
    return false if g_id==nil
    return false if g_id.to_i==0
    day   = Time.now     if day==nil
    g = System::Group.find(g_id)
    if g.start_at <= day && g.end_at==nil
      return true
    end
    if g.start_at <= day && day < g.end_at
      return true
    end
    return false
  end

  def self.group_states(state)
    yaml = 'config/locales/table_field.yml'
    hx = Gw::NameValue.get('yaml', yaml, 'system_states')
    return hx.to_a.assoc(state)[1]
  end

  def self.show_status(state)
    states = Gw.yaml_to_array_for_select 'system_states'
    show_state = []
    states.each do |value,key|
      show_state << [key,value]
    end
    show = show_state.assoc(state)
    return show[1]
  end

  def self.get_gid(u_id = Site.user.id , day=nil)
    if day==nil
      ug_order  = "user_id ASC  , job_order ASC , start_at DESC "
      ug_cond   = "user_id = #{u_id} and job_order=0 and start_at <= '#{Date.today} 00:00:00' and (end_at IS null or end_at = '0000-00-00 00:00' or end_at > '#{Date.today} 00:00:00')"
      user_group = System::UsersGroupTemporary.find(:all , :conditions=> ug_cond ,:order => ug_order)
      if user_group.blank?
        return Site.user_group.id
      else
        return user_group[0].group_id
      end
    else
      ug_order  = "user_id ASC , start_at DESC , job_order ASC"
      ug_cond   = "user_id = #{u_id} and job_order=0 and start_at < #{day}"
      user_group = System::UsersGroupTemporary.find(:all , :conditions=> ug_cond ,:order => ug_order)
      return nil if user_group.blank?
      user_group.each do |g|
        return g.id if System::GroupTemporary.usable?(g.id , nil)==true
      end
      return nil
    end
  end

  def self.get_groups(user = Site.user)
    g_cond = "user_id=#{user.id}"
    g_order= "user_id ASC,start_at DESC"
    u_groups = System::UsersGroupTemporary.find(:all,:conditions=>g_cond,:order=>g_order)
    return nil if u_groups.blank?
    groups = []
    u_groups.each do |ug|
      groups << System::GroupTemporary.find(ug.group_id)
    end
    return groups
  end

  def self.select_dd_group(day=nil,level=nil,parent_id=nil,all=nil)
    day   = Time.now     if day==nil
    dd_lists = []
    dd_lists << ['すべて',0] if all == 'all'
    if parent_id ==nil
      if level==nil
        dd_lists = System::GroupTemporary.self.select_dd_tree(all)
      else

      end
    else
      g_order="code ASC , start_at DESC"
      g_cond="parent_id='#{parent_id}' and state = 'enabled'"
      groups = System::GroupTemporary.find(:all,:conditions=>g_cond,:orde=>g_order)
      groups.each do |g|
        next if System::GroupTemporary.usable?(g.id , "#{day}" )==false
        dd_lists << ['('+g.code+')'+g.name,g.id]
      end unless groups.blank?
    end
  end

  def self.select_dd_tree(all=nil)
    dd_lists = []
    dd_lists << ['すべて',0] if all == 'all'
    roots = System::GroupTemporary.find(:all,:conditions=>"level_no=1 and state='enabled'")
    roots.each do |r|
      dd_lists << [r.name+'('+r.code+')',r.id]
      dd_lists = System::GroupTemporary.get_childs(dd_lists,r)
    end
    return dd_lists
  end

  def self.get_childs(dd_lists,parent)
    c_lists = dd_lists
    childs = System::GroupTemporary.find(:all,:conditions=>"state='enabled' and parent_id=#{parent.id}")
    return c_lists if childs.blank?
    pad_str = "　"*(parent.level_no.to_i-1)*2+"+"+"-"*(parent.level_no.to_i)*2
    childs.each do |c|
      c_lists << [pad_str+c.name+'('+c.code+')',c.id]
      c_lists = System::GroupTemporary.get_childs(c_lists,c)
    end
    return c_lists
  end

  def self.get_group_tree(_group_id)
    _groups = []

    if _group_id.blank?
        _dept_conditions =  "state = 'enabled'"
        _dept_conditions << " and level_no = 2"
        _dept_conditions << " and parent_id = 1"
        _dep_order = "code ASC"
        _departments = System::GroupTemporary.find(:all , :conditions => _dept_conditions ,:order => _dep_order )

        _departments.each do | _dep |
        _groups << _dep
            _sec_conditions =  "state = 'enabled'"
            _sec_conditions << " and level_no = 3"
            _sec_conditions << " and parent_id = #{_dep.id}"
            _sec_order = "code ASC"
            _sections = System::GroupTemporary.find(:all , :conditions => _sec_conditions ,:order => _sec_order )

            _sections.each do | _sec |
                _groups << _sec
            end
        end
    else
        _dep = System::GroupTemporary.find(_group_id)
        _groups << _dep
        if _dep.level_no == 2
            _sec_conditions =  "state = 'enabled'"
            _sec_conditions << " and level_no = 3"
            _sec_conditions << " and parent_id = #{_dep.id}"
            _sec_order = "code ASC"
            _sections = System::GroupTemporary.find(:all , :conditions => _sec_conditions ,:order => _sec_order )

            _sections.each do | _sec |
                _groups << _sec
            end
        end
    end
    return _groups
  end

  def job_order_s
    yaml = 'config/locales/table_field.yml'
    hx = Gw::NameValue.get('yaml', yaml, 'system_groups_job_order')
    hx[job_order.to_i]
  end

  def self.ldap_show(ldap)
    ldap_state = []
    ldaps = Gw.yaml_to_array_for_select 'system_users_ldaps'
    ldaps.each do |value , key|
      ldap_state << [key,value]
    end
    ldap_str = ldap_state.assoc(ldap.to_i)
    return ldap_str[1]
  end

  def self.truncate_table(table_name=nil)
    return if table_name==nil
    connect = self.connection()
    truncate_query = "TRUNCATE TABLE `#{table_name}` ;"
    connect.execute(truncate_query)
  end

  def self.drop_table(table_name=nil)
    return if table_name==nil
    connect = self.connection()
    drop_query = "DROP TABLE IF EXISTS `#{table_name}`;"
    connect.execute(drop_query)
  end

  def self.create_table(table_name=nil,org_table='system_groups')
    return if table_name==nil
    connect = self.connection()
    create_query = "CREATE  TABLE  `#{table_name}` LIKE `#{org_table}`;"
    connect.execute(create_query)
  end

  def self.insert_table(table_name=nil,org_table='system_groups')
    return if table_name==nil
    connect = self.connection()
    insert_query = "INSERT INTO `#{table_name}` SELECT * FROM `#{org_table}`;"
    connect.execute(insert_query)
  end

end
