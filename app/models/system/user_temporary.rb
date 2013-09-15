require 'digest/sha1'
class System::UserTemporary < ActiveRecord::Base
  include System::Model::Base
  include System::Model::Base::Config
  include Cms::Model::Base::Content

  belongs_to :status,     :foreign_key => :state,   :class_name => 'System::Base::Status'
  has_many :user_groups,   :foreign_key => :user_id, :class_name => 'System::UsersGroupTemporary'
  has_and_belongs_to_many :groups, :class_name => 'System::GroupTemporary', :join_table => 'system_users_group_temporaries',
     :order => 'job_order,system_group_temporaries.sort_no'

  attr_accessor :in_password
  attr_accessor :encrypted_password

  validates_presence_of     :code, :name, :state, :ldap
  validates_uniqueness_of   :code

  before_save :encrypt_password

  @@ldap_class = System::Lib::Ldap

  def self.get_user_select(g_id=nil,all=nil)
    selects = []
    selects << ['すべて',0] if all=='all'
    if g_id.blank?
      u = Site.user
      g = u.groups[0]
      gid = g.id
    else
      gid = g_id
    end
    conditions="state='enabled' and (id in (select user_id from system_users_groups where group_id = #{gid}))"
    order = "code"
    users_select = System::UserTemporary.find(:all,:conditions=>conditions,:select=>"id,code,name",:order=>order)
    selects = users_select.map{|user| [ Gw.trim(user.display_name),user.id]}
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
    "#{name} (#{code.to_s})"
  end

  def label(name)
    case name; when nil; end
  end

  def delete_group_relations
    System::UsersGroupTemporary.delete_all(:user_id => id)
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

    user.encrypted_password = Util::Crypt.encrypt in_password
    return user

 end

  def self.encrypt(in_password, salt)
    in_password
  end

  def encrypt(in_password)
    in_password
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

  def self.create_table(table_name=nil,org_table='system_users')
    return if table_name==nil
    connect = self.connection()
    create_query = "CREATE  TABLE  `#{table_name}` LIKE `#{org_table}`;"
    connect.execute(create_query)
  end

  def self.insert_table(table_name=nil,org_table='system_users')
    return if table_name==nil
    connect = self.connection()
    insert_query = "INSERT INTO `#{table_name}` SELECT * FROM `#{org_table}`;"
    connect.execute(insert_query)
  end

protected
  def encrypt_password
    return if in_password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{account}--") if new_record?
    self.password = encrypt(in_password)
  end

  def password_required?
    password.blank? || !in_password.blank?
  end
end
