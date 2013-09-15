require 'digest/sha1'
class System::User < ActiveRecord::Base
  include System::Model::Base
  include System::Model::Base::Config
  include Cms::Model::Base::Content

  belongs_to :status,     :foreign_key => :state,   :class_name => 'System::Base::Status'
  has_many :user_groups,   :foreign_key => :user_id, :class_name => 'System::UsersGroup'
  has_and_belongs_to_many :groups, :class_name => 'System::Group',
    :join_table => 'system_users_groups', :order => 'job_order,system_groups.sort_no'
  has_many :user_groups_hist,   :foreign_key => :user_id, :class_name => 'System::UsersGroupHistory'
  has_and_belongs_to_many :groups_hist, :class_name => 'System::GroupHistory',
    :join_table => 'system_users_group_histories', :order => 'job_order,system_group_histories.sort_no'
  has_many :user_custom_groups, :foreign_key => :user_id, :class_name => 'System::UsersCustomGroup'

  has_many :logins, :foreign_key => :user_id, :class_name => 'System::LoginLog',
    :order => 'id desc', :dependent => :delete_all

  attr_accessor :in_password

  validates_presence_of     :code, :name, :state, :ldap
  validates_uniqueness_of   :code

  before_save :encrypt_password

  @@ldap_class = System::Lib::Ldap

  def mobile_pass_check
    valid = true
    if self.mobile_password.size < 4
        self.errors.add :mobile_password, 'は４文字以上で入力してください。'
        valid = false
    end
    return valid
  end

  def self.m_access_select
    return [['不許可（標準）',0],['許可',1]]
  end

  def self.m_access_show(access)
    m_acc = [[0,'不許可（標準）'],[1,'許可']]
    show_str = m_acc.assoc(access.to_i)
    if show_str.blank?
      return nil
    else
      return show_str[1]
    end
  end

  def self.is_dev?(uid = Site.user.id)
    System::Model::Role.get(1, uid ,'_admin', 'developer')
  end

  def self.is_admin?(uid = Site.user.id)
    System::Model::Role.get(1, uid ,'_admin', 'admin')
  end

  def self.is_editor?(uid = Site.user.id)
    System::Model::Role.get(1, uid ,'system_users', 'editor')
  end

  def self.get_user_select(g_id=nil,all=nil, options = {})
    selects = []
    selects << ['すべて',0] if all=='all'
    if g_id.blank?
      u = Site.user
      g = u.groups[0]
      gid = g.id
    else
      gid = g_id
    end

    f_ldap = ''
    f_ldap = '1' if options[:ldap] == 1
    f_ldap = '' if Site.user.code.length <= 3
    f_ldap = '' if Site.user.code == 'gwbbs'
    conditions="state='enabled' and system_users_groups.group_id = #{gid}" if f_ldap.blank?
    conditions="state='enabled' and system_users_groups.group_id = #{gid} and system_users.ldap = 1" unless f_ldap.blank?
    order = "code"
    users_select = System::User.find(:all,:conditions=>conditions,:select=>"id,code,name",:order=>order,:joins=>'left join system_users_groups on system_users.id = system_users_groups.user_id')
    selects += users_select.map{|user| [ Gw.trim(user.display_name),user.id]}
    return selects
  end

  def self.user_states
    Gw.yaml_to_array_for_select 'system_states'
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

  def self.get(uid=nil)
    uid = Site.user.id if uid.nil?
    self.find(:first, :conditions=>"id=#{uid}")
  end

  def ldap_states
    {'0' => '非同期', '1' => '同期'}
  end

  def display_name
    #    "#{name} (#{id.to_s})"
    Gw.user_display_name(id, name)
  end

  def label(name)
    case name; when nil; end
  end


  def delete_group_relations
    System::UsersGroup.delete_all(:user_id => id)
    return true
  end

  def search(params)
    params.each do |n, v|
      next if v.to_s == ''

      case n
      when 's_keyword'
        search_keyword v, :code , :name , :name_en , :email
      end
    end if params.size != 0

    return self
  end
  def has_auth?(name)
    auth = {
      :none     => 0,
      :reader   => 1,
      :creator  => 2,
      :editor   => 3,
      :designer => 4,
      :manager  => 5,
      }

    return 5
  end

  def has_priv?(action, options = {})
    return true
    return true if has_auth?(:manager)
    return nil unless options[:item]

    item = options[:item]
    if item.kind_of?(ActiveRecord::Base)
      item = item.unid
    end

    cond  = "user_id = :user_id"
    cond += " AND role_id IN (" +
      " SELECT role_id FROM system_object_privileges" +
      " WHERE action = :action AND item_unid = :item_unid )"
    params = {
      :user_id   => id,
      :action    => action.to_s,
      :item_unid => item,
    }
    System::UsersRole.find(:first, :conditions => [cond, params])
  end

  def self.logger
    @@logger ||= RAILS_DEFAULT_LOGGER
  end

  def self.authenticate(in_account, in_password, encrypted = false)
    in_password = Util::Crypt.decrypt(in_password) if encrypted

    begin
      conditions = "state = 'enabled' and code = '#{in_account}'"
      user = self.new.find(:first, :conditions => conditions)
      raise ActiveRecord::RecordNotFound if user.nil?
    rescue
      return false
    end

    if user.ldap == 0
      return false if in_password != user.password || user.password.to_s == ''
    else
      return false unless conn = @@ldap_class.bind(in_account, in_password)
    end

    return user
  end

  def self.encrypt(in_password, salt)
    in_password
  end

  def encrypt(in_password)
    in_password
  end

  def encrypt_password
    return if password.blank?
    Util::Crypt.encrypt(password)
  end

  def authenticated?(in_password)
    password == encrypt(in_password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at
  end

  def remember_me
    self.remember_token_expires_at = 2.weeks.from_now.utc
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  def self.truncate_table
    connect = self.connection()
    truncate_query = "TRUNCATE TABLE `system_users` ;"
    connect.execute(truncate_query)
  end

  def previous_login_date
    return @previous_login_date if @previous_login_date
    if (list = logins.find(:all, :limit => 2)).size != 2
      return nil
    end
    @previous_login_date = list[1].login_at
  end

protected
  def password_required?
    password.blank? || !in_password.blank?
  end
end
