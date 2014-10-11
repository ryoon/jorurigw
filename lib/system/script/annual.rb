# -*- encoding: utf-8 -*-
#######################################################################
#年次所属切り替え更新処理
########################################################################

class System::Script::Annual

  # 振替用テーブル作成(2013年版)
  # /opt/ruby-enterprise-1.8.7-2010.02/bin/ruby /var/share/gw_dev/script/runner -e development 'System::Script::Annual.create_gwsub_renew_groups'
  def self.create_gwsub_renew_groups
    p "create_renew_groups 開始:#{Time.now}."
    group_nexts = System::GroupNext.find(:all, :conditions=>"created_at > '2013-01-01 00:00'", :order=> 'id')
    group_nexts.each do |group_next|
      group_old_g = group_next.old_g
      group_old_parent_g = group_old_g.parent
      group_update = System::GroupUpdate.find(:first, :conditions=>"id = #{group_next.group_update_id} and start_at > '2013-01-01 00:00'")
      group_update_parent1 = group_update.parent1

      next if group_update.blank?
      if group_update.present?
        renewal = Gwsub::RenewalGroup.new
        renewal.prev_p_g_id    = group_old_parent_g.id
        renewal.prev_p_g_code  = group_old_parent_g.code
        renewal.prev_p_g_name  = group_old_parent_g.name
        renewal.prev_g_id      = group_old_g.id
        renewal.prev_g_code    = group_old_g.code
        renewal.prev_g_name    = group_old_g.name

        renewal.next_p_g_id    = group_update.parent_id
        renewal.next_p_g_code  = group_update.parent_code
        renewal.next_p_g_name  = group_update.parent_name
        renewal.next_g_id      = group_update.group_id
        renewal.next_g_code    = group_update.code
        renewal.next_g_name    = group_update.name

        renewal.save(false)
      end
    end
    p "create_renew_groups 終了:#{Time.now}."
  end

  # 振替用テーブル作成(2013年版)
  # /opt/ruby-enterprise-1.8.7-2010.02/bin/ruby /var/share/gw_dev/script/runner -e development 'System::Script::Annual.create_renew_groups_2013'
  def self.create_renew_groups_2013
    p "create_renew_groups 開始:#{Time.now}."
    group_nexts = System::GroupNext.find(:all, :conditions=>"created_at > '2013-01-01 00:00'", :order=> 'id')
    group_nexts.each do |group_next|
      group_update = System::GroupUpdate.find(:first, :conditions=>"id = #{group_next.group_update_id} and start_at > '2013-01-01 00:00'")

      next if group_update.blank?

      if group_update.present?
        renewal = Gwboard::RenewalGroup.new
        renewal.present_group_id    = group_next.old_group_id
        renewal.present_group_code  = group_next.old_code
        renewal.present_group_name  = group_next.old_name
        renewal.incoming_group_id   = group_update.group_id
        renewal.incoming_group_code = group_update.code
        renewal.incoming_group_name = group_update.name
        renewal.save(false)
      end
    end
    p "create_renew_groups 終了:#{Time.now}."
  end

  # 振替用テーブル作成(2012年版)
  # /opt/ruby-enterprise-1.8.7-2010.02/bin/ruby /var/share/gw_dev/script/runner -e development 'System::Script::Annual.create_renew_groups_2012'
  def self.create_renew_groups_2012
    p "create_renew_groups 開始:#{Time.now}."
    group_nexts = System::GroupNext.find(:all, :conditions=>"created_at > '2012-01-01 00:00'", :order=> 'id')
    group_nexts.each do |group_next|
      group_update = System::GroupUpdate.find(:first, :conditions=>"id = #{group_next.group_update_id} and start_at > '2012-01-01 00:00'")

      next if group_update.blank?

      if group_update.present?
        renewal = Gwboard::RenewalGroup.new
        renewal.present_group_id    = group_next.old_group_id
        renewal.present_group_code  = group_next.old_code
        renewal.present_group_name  = group_next.old_name
        renewal.incoming_group_id   = group_update.group_id
        renewal.incoming_group_code = group_update.code
        renewal.incoming_group_name = group_update.name
        renewal.save(false)
      end
    end

    # 企画総務部→経営戦略部
    keiei_senryakus = System::GroupHistoryTemporary.find(:all, :conditions=>"parent_id = 700 and start_at > '2012-01-01 00:00'", :order=> 'id')
    keiei_senryakus.each do |senryaku|
      soumu = System::GroupHistoryTemporary.find(:first, :conditions=>"parent_id = 3 and code = '#{senryaku.code}'")

      if soumu.present?
        renewal = Gwboard::RenewalGroup.new
        renewal.present_group_id    = soumu.id
        renewal.present_group_code  = soumu.code
        renewal.present_group_name  = soumu.name
        renewal.incoming_group_id   = senryaku.id
        renewal.incoming_group_code = senryaku.code
        renewal.incoming_group_name = senryaku.name
        renewal.save(false)
      end
    end

    p "create_renew_groups 終了:#{Time.now}."
  end

  # 振替用テーブル作成
  # /opt/ruby-enterprise-1.8.7-2010.02/bin/ruby /var/share/gw_dev/script/runner -e development 'System::Script::Annual.system_roles_renew'
  def self.system_roles_renew(start_date = nil)
    if start_date.blank?
      return false
    else
      @start_date = start_date
    end
    p "system_roles_renew 開始:#{Time.now}."
    r_groups = Gwboard::RenewalGroup.find(:all, :conditions => ["start_date = ?", @start_date], :order=> 'present_group_id, present_group_code')

    r_groups.each do |r_group|
      ids = Array.new
      update_fields1  = "group_id = #{r_group.incoming_group_id}"
      sql_where1      = "group_id = #{r_group.present_group_id}"
      _ids = System::Role.find(:all, :conditions => sql_where1, :select => "id")
      unless _ids.empty?
        _ids.each do |_id|
          ids << _id.id
        end
        ids = ids.uniq
        System::Role.update_all(update_fields1, sql_where1)
        p "system_roles　対象ID：[#{Gw.join(ids, ',')}], 変更対象所属：#{sql_where1}, 更新SQL：#{update_fields1}, #{Time.now}."
      end

      ids = Array.new
      update_fields1  = "uid = #{r_group.incoming_group_id}"
      sql_where1      = "uid = #{r_group.present_group_id} and class_id = 2"
      _ids = System::Role.find(:all, :conditions => sql_where1, :select => "id")
      unless _ids.empty?
        _ids.each do |_id|
          ids << _id.id
        end
        ids = ids.uniq
        System::Role.update_all(update_fields1, sql_where1)
        p "system_roles　対象ID：[#{Gw.join(ids, ',')}], 変更対象所属：#{sql_where1}, 更新SQL：#{update_fields1}, #{Time.now}."
      end
    end
    p "system_roles_renew 終了:#{Time.now}."
  end
end
