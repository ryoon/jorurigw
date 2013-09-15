class Gw::ScheduleList < Gw::Database
  include System::Model::Base
  include Cms::Model::Base::Content

  def self.params_set(params)
    ret = ""
    'uid:s_year:s_month'.split(':').each_with_index do |col, idx|
      unless params[col.to_sym].blank?
        ret += "&" unless ret.blank?
        ret += "#{col}=#{params[col.to_sym]}"
      end
    end
    ret = '?' + ret unless ret.blank?
    return ret
  end

  def self.get_users(gid = Site.user_group.id)
    join = "inner join system_users_groups on system_users.id = system_users_groups.user_id"
    join += " inner join system_users_custom_groups on system_users.id = system_users_custom_groups.user_id"
    cond = "system_users.state='enabled' and system_users_groups.group_id = #{gid}"
    users = System::User.find(:all, :conditions=>cond, :order=>'sort_no, code',
        :joins=>join, :group => 'system_users.id')

    return users
  end

  def self.group_equal(uid = nil)

    return false if uid.blank?

    user = System::User.find(:first, :conditions => "id = #{uid}")
    return false if user.blank?

    return false if user.user_groups.empty? || user.user_groups[0].group.blank?
    group = user.user_groups[0].group

    if Site.user_group.id.to_i == group.id.to_i
      return true
    else
      return false
    end

  end

  def self.get_list_usernames(item)
    _names = Array.new
    names = ""
    len = item.schedule_users.length
    if len > 0
      item.schedule_users.each_with_index do |user, i|
        begin
          case user.class_id
          when 0
          when 1
            _user = user.user
            if _user.blank? || user.user.state != 'enabled'
            else
              _names << "#{user.user.name}"
            end
          when 2
            _group = user.group
            if _group.blank? || _group.state != 'enabled'
            else
              _names << "#{user.group.name}"
            end
          end
        rescue
        end
      end
    end
    names = Gw.join(_names, ',')
    return names
  end
end
