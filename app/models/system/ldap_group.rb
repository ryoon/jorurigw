class System::LdapGroup < ActiveLdap::Base
  ldap_mapping :dn_attribute => 'ou',
    :prefix  => '',
    :classes => ['top', 'organizationalunit']

  def user
    return @user if @user
    filter = ''
    filter << "(o=" + dn.to_s.gsub(/^ou=.*ou=(.*?),.*/, '\1') + ")"
    filter << "(cn=" + ou.gsub(/^[0-9a-zA-Z]+(.*)/, '\1') + ")"
    @user = System::LdapUser.find(:filter => filter )
  end

  def users
    return @users if @users
    base  = dn
    filter = ""
    @users = System::LdapUser.find(:all, :base=>base,:filter => filter,:scope=>:one)

  end

  def synchro_target?
    return false if ou =~ /^(Groups|People|Special Users)$/i
    return ou =~ /^[\w]/ ? true : nil
  end

  def db_value(name)
    case name
    when :code
      return ou.gsub(/^([0-9a-zA-Z]+)(.*)/, '\1')
    when :name
      return ou.gsub(/^([0-9a-zA-Z]+)(.*)/, '\2')
    when :name_en
      return user ? user.get('cn;lang-en') : nil
    when :email
      return user ? user.get('mail') : nil
    end
  end

  def self.pp(data)
    Cms::Lib::Debugger::Dump.execute(data)
  end

  def pp(data)
    Cms::Lib::Debugger::Dump.execute(data)
  end

  def parents
    current = self
    parents = [current]
    while p = current.parent
      parents.unshift(p)
      current = p
    end
    return parents
  end

  def self.find_one(options = {})
    prefix = nil
    if options[:parent]
      prefix = "ou=#{options[:parent].ou}"
    end
    find(:all, :prefix => prefix, :scope => :one )
  end

  def self.find_departments
    filter = '(objectClass=organizationalunit)'
    tmp = ActiveLdap::Base.search(:filter => filter)

    groups = []
    tmp.each do |g|
      next if g[0] =~ /ou=.*,.*ou=/
      next if g[0] =~ /ou=(Groups|People|Special Users),/i
      groups << g
    end
    return groups
  rescue ActiveLdap::LdapError::AdminlimitExceeded
    raise 'Error: LDAP通信時間超過'
  rescue
    raise 'Error: LDAP Error'
  end

  def self.find_sections(parent)
    filter = '(objectClass=organizationalPerson)'
    filter << "(o=#{parent})"
    return ActiveLdap::Base.search(:filter => filter)
  rescue ActiveLdap::LdapError::AdminlimitExceeded
    raise 'Error: LDAP通信時間超過'
  rescue
    raise 'Error: LDAP Error'
  end

  def self.find_all_as_tree
    keys   = {}
    groups = []

    find_departments.each do |dep|
      ou          = dep[1]['ou'][0]
      dep_id      = ou.sub(/^([0-9a-zA-Z]+).*/, '\1')
      dep_name    = ou.sub(/^[0-9a-zA-Z]+(.*)/, '\1')
      dep_name_en = dep[1]['sn'] ? dep[1]['sn'][1]['lang-en'][0] : nil
      dep_dup     = keys.has_key?(dep_id) ? true : nil
      keys[dep_id] = true

      sections = []
      find_sections(ou).each do |sec|
        sec_id      = sec[1]['ou'][0].sub(/^([0-9a-zA-Z]+).*/, '\1')
        sec_name_en = sec[1]['sn'] ? sec[1]['sn'][1]['lang-en'][0] : nil
        sec_dup     = keys.has_key?(sec_id) ? true : nil
        keys[sec_id] = false

        sections << {
          :id         => sec_id,
          :parent_id  => dep_id,
          :level_no   => 3,
          :name       => sec[1]['cn'][0],
          :name_en    => sec_name_en,
          :email      => sec[1]['mail'][0],
          :duplicated => sec_dup,
        }
      end

      groups << {
        :id         => dep_id,
        :parent_id  => 1,
        :level_no   => 2,
        :name       => dep_name,
        :name_en    => dep_name_en,
        :email      => nil,
        :sections   => sections,
        :duplicated => dep_dup,
      }
    end

    return groups
  end
end
