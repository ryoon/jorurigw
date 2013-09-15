class System::UsersGroupTemporary < ActiveRecord::Base
  include System::Model::Base
  include System::Model::Base::Config

  set_primary_key 'rid'

  belongs_to   :user_r,  :foreign_key => :user_id,  :class_name => 'System::UserTemporary'
  belongs_to   :group_r, :foreign_key => :group_id, :class_name => 'System::GroupTemporary'

  validates_presence_of :group_id,:user_id,:start_at

  validates_each :end_at do |record, attr, value|
    record.errors.add attr, 'には適用開始日以降の日付を入力してください'  if value.blank? ? false : (value < record.start_at)
  end

  before_save :set_columns
  def set_columns
    if self.user_id.to_i==0
        self.user_code  = '未登録ユーザー'
    else
      if self.user_r.blank?
        self.user_code  = '未登録ユーザー'
      else
        self.user_code  = self.user_r.code
      end
    end
    if self.group_id.to_i==0
        self.group_code  = '未登録グループ'
    else
      if self.group_r.blank?
        self.group_code  = '未登録グループ'
      else
        self.group_code  = self.group_r.code
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

  def self.truncate_table(table_name=nil)
    return if table_name==nil
    connect = self.connection()
    truncate_query = "TRUNCATE TABLE `#{table_name}` ;"
    connect.execute(truncate_query)
  end

  def self.drop_table(table_name=nil)
    return if table_name==nil
    connect = self.connection()
    drop_query = "DROP TABLE IF EXISTS `#{table_name}` ;"
    connect.execute(drop_query)
  end

  def self.create_table(table_name=nil,org_table='system_users_groups')
    return if table_name==nil
    connect = self.connection()
    create_query = "CREATE  TABLE  `#{table_name}` LIKE `#{org_table}`;"
    connect.execute(create_query)
  end

  def self.insert_table(table_name=nil,org_table='system_users_groups')
    return if table_name==nil
    connect = self.connection()
    insert_query = "INSERT INTO `#{table_name}` SELECT * FROM `#{org_table}` where end_at is null ;"
    connect.execute(insert_query)
  end

end
