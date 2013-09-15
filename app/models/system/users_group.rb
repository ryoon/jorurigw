class System::UsersGroup < ActiveRecord::Base
  include System::Model::Base
  include System::Model::Base::Config

  set_primary_key 'rid'

  belongs_to   :user,  :foreign_key => :user_id,  :class_name => 'System::User'
  belongs_to   :group, :foreign_key => :group_id, :class_name => 'System::Group'

  validates_presence_of :group_id,:user_id,:start_at

  validates_each :end_at do |record, attr, value|
    record.errors.add attr, 'には適用開始日以降の日付を入力してください'  if value.blank? ? false : (value < record.start_at)
  end

  before_save :set_columns
  def set_columns
    if self.user_id.to_i==0
        self.user_code  = '未登録ユーザー'
    else
      if self.user.blank?
        self.user_code  = '未登録ユーザー'
      else
        self.user_code  = self.user.code
      end
    end
    if self.group_id.to_i==0
        self.group_code  = '未登録グループ'
    else
      if self.group.blank?
        self.group_code  = '未登録グループ'
      else
        self.group_code  = self.group.code
      end
    end
  end

  def self.select_state
    Gw.yaml_to_array_for_select 'system_ugs_job_orders'
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

  def self.state_show(state)
    state_state = []
    states = Gw.yaml_to_array_for_select 'system_states'
    states.each do |value , key|
      state_state << [key,value]
    end
    state_str = state_state.assoc(state)
    return state_str[1]
  end

  def self.get_gname(uid=nil)
    uid = Site.user.id if uid.nil?
    user_group1 = System::UsersGroup.find(:first, :conditions=>"user_id=#{uid}",:order=>"job_order")
    return nil if user_group1.blank?
    group       = user_group1.group unless user_group1.blank?
    name = group.ou_name unless group.blank?
    name = nil if group.blank?
    return name
  end

  def search(params)
    params.each do |n, v|
      next if v.to_s == ''

      case n
        when 's_keyword'
        search_keyword v, :job_order
        when 'job'
        search_id v, :job_order
      end
    end if params.size != 0

    return self
  end

  def self.truncate_table
    connect = self.connection()
    truncate_query = "TRUNCATE TABLE `system_users_groups` ;"
    connect.execute(truncate_query)
  end
end
