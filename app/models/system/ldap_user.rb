class System::LdapUser < ActiveLdap::Base
  ldap_mapping :dn_attribute => 'uid',
    :prefix  => '',
    :classes => ['top', 'organizationalPerson']

  def pp(data)
    Cms::Lib::Debugger::Dump.execute(data)
  end

  def synchro_target?
    return true
  end

  def get(name)
    opt = nil
    if name =~ /;/
      tmp = name.split(/;/)
      name = tmp[0]
      opt  = tmp[1]
    end
    value = send(name)
    return value if value.class != Array
    return value[0] unless opt
    value.each {|v| return v[opt] if v.class == Hash }
    return nil
  end

  def self.find_users(group = nil)
    filter = '(objectClass=organizationalPerson)'
    base = group.dn if group
    base = nil unless group
    ActiveLdap::Base.search(:filter => filter,:scope=>:one,:base=>base)
  rescue ActiveLdap::LdapError::AdminlimitExceeded
    raise 'Error: LDAP通信時間超過'
  rescue
    raise 'Error: LDAP Error'
  end

  def self.find_all_as_tree
    keys  = {}
    users = []

    find_users.each do |user|
      ou      = user[1]['ou'][0]
      id      = user[1]['uid'][0]
      name_en = user[1]['sn'] ? user[1]['sn'][1]['lang-en'][0] : nil
      name_en += ' ' + user[1]['givenName'][0]['lang-en'][0] if name_en && defined?(user[1]['givenName'][0]['lang-en'][0])
      dup     = keys.has_key?(id) ? true : nil

      keys[id] = true

      users << {
        :id         => id,
        :group_id   => ou.sub(/^([0-9]+).*/, '\1'),
        :name       => user[1]['cn'][0],
        :name_en    => name_en,
        :email      => user[1]['mail'][0],
        :duplicated => dup,
      }
    end

    return users
  end
end
