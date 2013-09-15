class System::Admin::GroupChangesController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
    item = System::GroupChange.new
    item.order "created_at DESC , updated_at DESC"
    @item_latest=item.find(:first)
  end

  def index
    @current='main'
      item = System::GroupChange.new
      item.page  params[:page], params[:limit]
      item.order "created_at DESC , updated_at DESC"
      @items = item.find(:first)
      _index @items
  end

  def prepare
    @current='prepare'
    item = System::GroupChange.new
    item.state = '1'
    item.order "created_at DESC , updated_at DESC"
    @item=item.find(:first)
  end

  def reflects
    rtn = System::GroupChange.check_sequence(@item_latest,'reflects')
    if rtn == false
        flash[:notice] = "実行順序が違っています。"
        redirect_to :action=>'index'
        return
    end

    @current='reflects'
    item = System::GroupChange.new
    item.state = '3'
    item.order "created_at DESC , updated_at DESC"
    @item=item.find(:first)
  end

  def pickup
    rtn = System::GroupChange.check_sequence(@item_latest,'pickup')
    if rtn == false
        flash[:notice] = "実行順序が違っています。"
        redirect_to :action=>'index'
        return
    end
    @current='pickup'
    pickup_date = System::GroupChangePickup.new
    pickup_date.order "target_at DESC"
    @pickup_date = pickup_date.find(:first)
    item = System::GroupChange.new
    item.state = '7'
    item.order "created_at DESC , updated_at DESC"
    @item=item.find(:first)
  end

  def fixed
    rtn = System::GroupChange.check_sequence(@item_latest,'fixed')
    if rtn == false
        flash[:notice] = "実行順序が違っています。"
        redirect_to :action=>'index'
        return
    end
    @current='fixed'
    item = System::GroupChange.new
    item.state = '9'
    item.order "created_at DESC , updated_at DESC"
    @item=item.find(:first)
  end

  def csv
    rtn = System::GroupChange.check_sequence(@item_latest,'csv')
    if rtn == false
        flash[:notice] = "実行順序が違っています。"
        redirect_to :action=>'index'
        return
    end
    @current='csv'
    item = System::GroupChange.new
    item.state = '10'
    item.order "created_at DESC , updated_at DESC"
    @item=item.find(:first)
  end

  def deletes
    rtn = System::GroupChange.check_sequence(@item_latest,'deletes')
    if rtn == false
        flash[:notice] = "実行順序が違っています。"
        redirect_to :action=>'index'
        return
    end
    @current='deletes'
    item = System::GroupChange.new
    item.state = '1'
    item.order "created_at DESC , updated_at DESC"
    @item=item.find(:first)
  end

  def prepare_run
    System::GroupChange.make_record(@item_latest,'prepare')
    System::UserTemporary.drop_table('system_users_back')
    System::UserTemporary.create_table('system_users_back','system_users')
    System::UserTemporary.insert_table('system_users_back','system_users')
    System::GroupTemporary.drop_table('system_groups_back')
    System::GroupTemporary.create_table('system_groups_back','system_groups')
    System::GroupTemporary.insert_table('system_groups_back','system_groups')
    System::UsersGroupTemporary.drop_table('system_users_groups_back')
    System::UsersGroupTemporary.create_table('system_users_groups_back','system_users_groups')
    System::UsersGroupTemporary.insert_table('system_users_groups_back','system_users_groups')
    System::GroupHistoryTemporary.drop_table('system_group_histories_back')
    System::GroupHistoryTemporary.create_table('system_group_histories_back','system_group_histories')
    System::GroupHistoryTemporary.insert_table('system_group_histories_back','system_group_histories')
    System::UsersGroupHistoryTemporary.drop_table('system_users_group_histories_back')
    System::UsersGroupHistoryTemporary.create_table('system_users_group_histories_back','system_users_group_histories')
    System::UsersGroupHistoryTemporary.insert_table('system_users_group_histories_back','system_users_group_histories')

    System::UserTemporary.drop_table('system_user_temporaries')
    System::UserTemporary.create_table('system_user_temporaries','system_users')
    System::UserTemporary.insert_table('system_user_temporaries','system_users')
    System::GroupTemporary.drop_table('system_group_temporaries')
    System::GroupTemporary.create_table('system_group_temporaries','system_groups')
    System::GroupTemporary.insert_table('system_group_temporaries','system_groups')
    System::UsersGroupTemporary.drop_table('system_users_group_temporaries')
    System::UsersGroupTemporary.create_table('system_users_group_temporaries','system_users_groups')
    System::UsersGroupTemporary.insert_table('system_users_group_temporaries','system_users_groups')
    System::GroupHistoryTemporary.drop_table('system_group_history_temporaries')
    System::GroupHistoryTemporary.create_table('system_group_history_temporaries','system_group_histories')
    System::GroupHistoryTemporary.insert_table('system_group_history_temporaries','system_group_histories')
    System::UsersGroupHistoryTemporary.drop_table('system_users_group_history_temporaries')
    System::UsersGroupHistoryTemporary.create_table('system_users_group_history_temporaries','system_users_group_histories')
    System::UsersGroupHistoryTemporary.insert_table('system_users_group_history_temporaries','system_users_group_histories')

    System::GroupUpdate.truncate_table
    System::GroupNext.truncate_table

    redirect_to :action=>'index'
    return
  end

  def reflects_run
    rtn = System::GroupChange.check_sequence(@item_latest,'reflects')
    if rtn == false
        flash[:notice] = "実行順序が違っています。"
        redirect_to :action=>'index'
        return
    end
    rtn = reflects_run_check1
    if rtn == false
      flash[:notice] = "引継元が設定されていない所属があります。"
      redirect_to system_group_updates_path
      return
    end
    rtn = reflects_run_check2
    if rtn == false
      flash[:notice] = "引継元が設定されていない所属があります。"
      redirect_to system_group_updates_path
      return
    end
    rtn = reflects_run_check3
    if rtn == false
      flash[:notice] = "引継先が設定されていない廃止所属があります。"
      redirect_to system_group_updates_path
      return
    end

    System::GroupHistoryTemporary.drop_table('system_group_history_temporaries')
    System::GroupHistoryTemporary.create_table('system_group_history_temporaries','system_group_histories')
    System::GroupHistoryTemporary.insert_table('system_group_history_temporaries','system_group_histories')

    System::UsersGroupHistoryTemporary.drop_table('system_users_group_history_temporaries')
    System::UsersGroupHistoryTemporary.create_table('system_users_group_history_temporaries','system_users_group_histories')
    System::UsersGroupHistoryTemporary.insert_table('system_users_group_history_temporaries','system_users_group_histories')

        reflects_run_01
        reflects_run_02
        reflects_run_03
        reflects_run_04
        reflects_run_05
        reflects_run_07
        reflects_run_09
        reflects_run_11
        reflects_run_13
        reflects_run_15
        reflects_run_17
        reflects_run_18
        reflects_run_19
        reflects_run_20

    item = System::GroupChange.new
    item.state = '3'
    item.order "created_at DESC , updated_at DESC"
    @item=item.find(:first)
    System::GroupChange.make_record(@item,'reflects')
    redirect_to :action=>'index'
    return
  end

  def pickup_run
    rtn = System::GroupChange.check_sequence(@item_latest,'pickup')
    if rtn == false
        flash[:notice] = "実行順序が違っています。"
        redirect_to :action=>'index'
        return
    end

    System::GroupTemporary.truncate_table('system_group_temporaries')
    System::UsersGroupTemporary.truncate_table('system_users_group_temporaries')

    pickup    = System::GroupChangePickup.find(:first,:order=>'updated_at DESC')
    target_at = pickup.target_at

    group_conditions  = "start_at <= '#{target_at.strftime("%Y-%m-%d %H:%M:%S")}' and (end_at IS Null or end_at = '0000-00-00 00:00:00' or end_at >= '#{target_at.strftime("%Y-%m-%d %H:%M:%S")}' )"
    group_order       = "id"

    groups  = System::GroupHistoryTemporary.find(:all,:conditions=>group_conditions,:order=>group_order)

    unless groups.blank?
      groups.each do |g|
        item = System::GroupTemporary.new
        cols = g.attribute_names
        hs = {}
        cols.each do |c|
          hs[c] = "#{g.send(c)}"
        end
        item.send(:attributes=, hs , false)
        item.save(false)
      end
    end

    ug_conditions  = "start_at <= '#{target_at.strftime("%Y-%m-%d %H:%M:%S")}' and (end_at IS Null or end_at = '0000-00-00 00:00:00' or end_at >= '#{target_at.strftime("%Y-%m-%d %H:%M:%S")}')"
    ug_order       = "rid"

    ugs  = System::UsersGroupHistoryTemporary.find(:all,:conditions=>ug_conditions,:order=>ug_order)

    unless ugs.blank?
      ugs.each do |ug|
        item = System::UsersGroupTemporary.new
        cols = ug.attribute_names
        hs = {}
        cols.each do |c|
          hs[c] = "#{ug.send(c)}"
        end
        item.send(:attributes=, hs , false)
        item.save(false)
      end
    end

    item = System::GroupChange.new
    item.state = '7'
    item.order "created_at DESC , updated_at DESC"
    @item=item.find(:first)
    System::GroupChange.make_record(@item,'pickup',target_at)
    redirect_to :action=>'index'
    return
  end

  def fixed_run
    rtn = System::GroupChange.check_sequence(@item_latest,'fixed')
    if rtn == false
        flash[:notice] = "実行順序が違っています。"
        redirect_to :action=>'index'
        return
    end

    System::Group.truncate_table
    System::GroupTemporary.insert_table('system_groups','system_group_temporaries')

    System::User.truncate_table
    System::UserTemporary.insert_table('system_users','system_user_temporaries')

    System::UsersGroup.truncate_table
    System::UsersGroupTemporary.insert_table('system_users_groups','system_users_group_temporaries')

    System::GroupHistory.truncate_table
    System::GroupHistoryTemporary.insert_table('system_group_histories','system_group_history_temporaries')

    System::UsersGroupHistory.truncate_table
    System::UsersGroupHistoryTemporary.insert_table('system_users_group_histories','system_users_group_history_temporaries')

    item = System::GroupChange.new
    item.state = '9'
    item.order "created_at DESC , updated_at DESC"
    @item=item.find(:first)
    System::GroupChange.make_record(@item,'fixed')
    redirect_to :action=>'index'
    return
  end

  def csv_run
    rtn = System::GroupChange.check_sequence(@item_latest,'csv')
    if rtn == false
        flash[:notice] = "実行順序が違っています。"
        redirect_to :action=>'index'
        return
    end

    require 'rubygems'
    require 'zip/zipfilesystem'
    type_utf8 = '-w'
    put_csv = []
    put_base = "#{RAILS_ROOT}/tmp/gw_system_changes/"
    FileUtils.mkdir_p put_base

    fname1 = "#{put_base}system_users_#{Date.today}.csv"
    File.delete(fname1) if File.exist?(fname1)
    items1 = System::User.find(:all)
    unless items1.blank?
      ffile1 = File::open(fname1,"wb+")
      ffile1.puts(NKF::nkf(type_utf8,Gw::Script::Tool.ar_to_csv(items1)))
      ffile1.close
      put_csv << fname1
    end

    fname2 = "#{put_base}system_groups_#{Date.today}.csv"
    File.delete(fname2) if File.exist?(fname2)
    items2 = System::Group.find(:all)
    unless items2.blank?
      ffile2 = File::open(fname2,"wb+")
      ffile2.puts(NKF::nkf(type_utf8,Gw::Script::Tool.ar_to_csv(items2)))
      ffile2.close
      put_csv << fname2
    end

    fname3 = "#{put_base}system_users_groups_#{Date.today}.csv"
    File.delete(fname3) if File.exist?(fname3)
    items3 = System::UsersGroup.find(:all)
    unless items3.blank?
      ffile3 = File::open(fname3,"wb+")
      ffile3.puts(NKF::nkf(type_utf8,Gw::Script::Tool.ar_to_csv(items3)))
      ffile3.close
      put_csv << fname3
    end

    fname4 = "#{put_base}system_group_updates_#{Date.today}.csv"
    File.delete(fname4) if File.exist?(fname4)
    items4 = System::GroupUpdate.find(:all)
    unless items4.blank?
      ffile4 = File::open(fname4,"wb+")
      ffile4.puts(NKF::nkf(type_utf8,Gw::Script::Tool.ar_to_csv(items4)))
      ffile4.close
      put_csv << fname4
    end

    fname5 = "#{put_base}system_group_nexts_#{Date.today}.csv"
    File.delete(fname5) if File.exist?(fname5)
    items5 = System::GroupNext.find(:all)
    unless items5.blank?
      ffile5 = File::open(fname5,"wb+")
      ffile5.puts(NKF::nkf(type_utf8,Gw::Script::Tool.ar_to_csv(items5)))
      ffile5.close
      put_csv << fname5
    end

    run6_files = "#{put_base}system_group_changes_#{Date.today}.zip"
    File.delete(run6_files) if File.exist?(run6_files)
    run6_csv_zip(put_csv, run6_files)
    send_file run6_files

    item = System::GroupChange.new
    item.state = '10'
    item.order "created_at DESC , updated_at DESC"
    @item=item.find(:first)
    System::GroupChange.make_record(@item,'csv')

    return
  end

  def run6_csv_zip(src_paths, output_path)
    output_path = File.expand_path(output_path)
    zip_file = Zip::ZipFile.new(output_path, Zip::ZipFile::CREATE)
    src_paths.each do |src_path|
      src_path = File.expand_path(src_path)
      zip_file.add(File.basename(src_path), src_path)
    end
    zip_file.close()
  end

  def deletes_run
    rtn = System::GroupChange.check_sequence(@item_latest,'deletes')
    if rtn == false
        flash[:notice] = "実行順序が違っています。"
        redirect_to :action=>'index'
        return
    end

    System::UserTemporary.truncate_table('system_users_back')

    System::GroupTemporary.truncate_table('system_groups_back')

    System::UsersGroupTemporary.truncate_table('system_users_groups_back')

    System::GroupHistoryTemporary.truncate_table('system_group_histories_back')

    System::UsersGroupHistoryTemporary.truncate_table('system_users_group_histories_back')

    System::UserTemporary.truncate_table('system_user_temporaries')

    System::GroupTemporary.truncate_table('system_group_temporaries')

    System::UsersGroupTemporary.truncate_table('system_users_group_temporaries')

    System::GroupHistoryTemporary.truncate_table('system_group_history_temporaries')

    System::UsersGroupHistoryTemporary.truncate_table('system_users_group_history_temporaries')

    item = System::GroupChange.new
    item.state = '11'
    item.order "created_at DESC , updated_at DESC"
    @item=item.find(:first)
    System::GroupChange.make_record(@item,'deletes')
    redirect_to :action=>'index'
    return
  end

  def before_date(start_at=nil,count=1)
    return nil if start_at.blank?
    dates = Gw.get_parsed_date(start_at)
    return dates - count*24*60*60
  end

  def get_gid(level_no=nil,code=nil,name=nil,start_at=nil)
    return nil if level_no.blank?
    return nil if code.blank?
    return nil if name.blank?
    return nil if start_at.blank?
    group   = System::GroupHistoryTemporary.new
    group_cond = "level_no = #{level_no} and code = '#{code}' and name = '#{name}' and start_at <= '#{start_at.strftime("%Y-%m-%d %H:%M")}'"
    group_order = "sort_no"
    group1  = group.find(:first,:conditions=>group_cond,:order=>group_order)
    return nil if group1.blank?
    return group1.id
  end

  def reflects_run_check1
    update_g        = System::GroupUpdate.new
    update_g.state  = '1'
    update_groups   = update_g.find(:all)

    return true if update_groups.blank?

    update_groups.each do |g|
      next_g = System::GroupNext.new
      next_g.group_update_id = g.id
      n_groups = next_g.find(:all)

      return false if n_groups.blank?
    end
    return true
  end

  def reflects_run_check2
    return true
  end

  def reflects_run_check3

    update_g        = System::GroupUpdate.new
    update_g.state  = '3'
    update_groups   = update_g.find(:all)

    return true if update_groups.blank?

    next_g          = System::GroupNext.new
    next_g.order    "old_group_id"
    next_group_id1  = next_g.find(:all)
    return false if next_group_id1.blank?
    next_group_ids = []
    next_group_id1.each do |n|
      next_group_ids << n.old_group_id
    end

    update_g          = System::GroupUpdate.new
    update_g.state    = '3'
    update_g.level_no = 3
    update_groups     = update_g.find(:all)
    update_groups.each do |ug|
      check = next_group_ids.index(ug.group_id.to_i)
      if check.blank?
        return false
      end
    end unless update_groups.blank?

    update_g          = System::GroupUpdate.new
    update_g.state    = '3'
    update_g.level_no = 2
    update_groups     = update_g.find(:all)

    update_groups.each do |ug|
      check = next_group_ids.index(ug.group_id)
      if check.blank?

        child_groups = System::GroupHistoryTemporary.new
        child_groups.parent_id  = ug.group_id
        ug_children = child_groups.find(:all)

        return false if ug_children.blank?
        ug_children.each do |ug_c|
          check = next_group_ids.index(ug_c.id)
          if check.blank?

            return false
          end
        end
      end
    end unless update_groups.blank?
  end

  def reflects_run_01

    new_g = System::GroupUpdate.new
    new_g.level_no    = 2
    new_g.state       = '2'
    new_g.order     "code"
    new_gs = new_g.find(:all)

    return if new_gs.blank?

    new_gs.each do |g|
      if g.parent_id.to_i == 0
        parent_id = get_gid(g.level_no.to_i-1,g.parent_code,g.parent_name,g.start_at)
      else
        parent_id = g.parent_id
      end
      new_item = System::GroupHistoryTemporary.new
      new_item.parent_id    = parent_id
      new_item.state        = 'enabled'
      new_item.level_no     = g.level_no
      new_item.code         = g.code
      new_item.name         = g.name
      new_item.name_en      = nil
      new_item.email        = nil
      new_item.start_at     = g.start_at
      new_item.end_at       = nil
      new_item.sort_no      = 0
      new_item.ldap_version = nil
      new_item.ldap         = 0
      if new_item.save

        g.parent_id = parent_id if g.parent_id.to_i == 0
        g.group_id = new_item.id
        g.save(false)
      else
      end
    end
  end

  def reflects_run_02
    new_g = System::GroupUpdate.new
    new_g.level_no    = 2
    new_g.state       = '1'
    new_g.order     "code"
    new_gs = new_g.find(:all)

    return if new_gs.blank?

    new_gs.each do |g|

      before_group = System::GroupHistoryTemporary.find_by_id(g.group_id)
      unless before_group.blank?
        before_group.name     = g.name
        before_group.start_at = g.start_at
        before_group.save(false)
      end
    end
  end

  def reflects_run_03

    new_g = System::GroupUpdate.new
    new_g.level_no    = 3
    new_g.state       = '2'
    new_g.order     "code"
    new_gs = new_g.find(:all)

    return if new_gs.blank?

    new_gs.each do |g|
      if g.parent_id.to_i == 0

        parent_id = get_gid(g.level_no.to_i-1,g.parent_code,g.parent_name,g.start_at)
      else
        parent_id = g.parent_id
      end
      new_item = System::GroupHistoryTemporary.new
      new_item.parent_id    = parent_id
      new_item.state        = 'enabled'
      new_item.level_no     = g.level_no
      new_item.code         = g.code
      new_item.name         = g.name
      new_item.name_en      = nil
      new_item.email        = nil
      new_item.start_at     = g.start_at
      new_item.end_at       = nil
      new_item.sort_no      = 0
      new_item.ldap_version = nil
      new_item.ldap         = 0
      if new_item.save

        g.parent_id = parent_id if g.parent_id.to_i == 0
        g.group_id  = new_item.id
        g.save(false)
      else
      end
    end
  end

  def reflects_run_04

    new_g = System::GroupUpdate.new
    new_g.level_no    = 3
    new_g.state       = '1'
    new_g.order     "code"
    new_gs = new_g.find(:all)

    return if new_gs.blank?

    new_gs.each do |g|
      before_group = System::GroupHistoryTemporary.find_by_id(g.group_id)
      unless before_group.blank?
        before_group.name = g.name
        before_group.start_at = g.start_at
        before_group.save(false)
      end
    end
  end

  def reflects_run_05

    new_g = System::GroupUpdate.new
    new_g.level_no    = 2
    new_g.state       = '2'
    new_g.order     "code"
    new_gs = new_g.find(:all)

    return if new_gs.blank?

    ug_create_updates(new_gs)
  end

  def reflects_run_07
    return
  end

  def reflects_run_09

    new_g = System::GroupUpdate.new
    new_g.level_no    = 3
    new_g.state       = '2'
    new_g.order     "code"
    new_gs = new_g.find(:all)

    return if new_gs.blank?

    ug_create_updates(new_gs)
  end

  def reflects_run_11
    return
  end

  def reflects_run_13
    new_g = System::GroupUpdate.new
    new_g.level_no    = 2
    new_g.state       = '6'
    new_g.order     "code"
    new_gs = new_g.find(:all)

    return if new_gs.blank?

    ug_create_updates(new_gs)
  end

  def reflects_run_15

    new_g = System::GroupUpdate.new
    new_g.level_no    = 3
    new_g.state       = '6'
    new_g.order     "code"
    new_gs = new_g.find(:all)

    return if new_gs.blank?

    ug_create_updates(new_gs)
  end

  def reflects_run_17
    return
  end

  def reflects_run_18
    return
  end

  def reflects_run_19

    new_g = System::GroupUpdate.new
    new_g.level_no    = 3
    new_g.state       = '3'
    new_g.order     "code"
    new_gs = new_g.find(:all)

    return if new_gs.blank?
    new_gs.each do |g|
      end_date = before_date(g.start_at,1)
      g_id = g.group_id

      unless g_id.to_i==0
        new_item = System::GroupHistoryTemporary.find(g_id)
        new_item.end_at   = end_date
        new_item.save
      end
    end
  end

  def reflects_run_20

    new_g = System::GroupUpdate.new
    new_g.level_no    = 2
    new_g.state       = '3'
    new_g.order     "code"
    new_gs = new_g.find(:all)

    return if new_gs.blank?
    new_gs.each do |g|
      end_date = before_date(g.start_at,1)
      g_id = g.group_id

      unless g_id.to_i==0
        new_item = System::GroupHistoryTemporary.find(g_id)
        new_item.end_at   = end_date
        new_item.save
        child_cond = "parent_id=#{new_item.id}"
        childrens = System::GroupHistoryTemporary.find(:all,:conditions=>child_cond)
        childrens.each do |child1|
          child1.end_at   = end_date
          child1.save
        end
      end
    end
  end

  def ug_create_updates(new_gs)
    new_gs.each do |g|

      g_next  = System::GroupNext.new
      g_next.group_update_id = g.id
      g_nexts = g_next.find(:all)

      next if g_nexts.blank?

      g_nexts.each do |g_next|

        user_next_cond =  "group_id = #{g_next.old_group_id} and end_at IS NULL"
        user_next_order = "group_code"
        users_next = System::UsersGroupHistoryTemporary.find(:all , :conditions=>user_next_cond , :order=>user_next_order)

        next if users_next.blank?

        users_next.each do |ug|
          ug_next = System::UsersGroupHistoryTemporary.new
            ug_next.user_id     = ug.user_id
            ug_next.user_code   = ug.user_code
            ug_next.group_id    = g.group_id
            ug_next.group_code  = g.code
            ug_next.start_at    = g.start_at
            ug_next.job_order   = ug.job_order

          if ug_next.save
            ug.end_at = before_date(g.start_at,1)

            ug.save(false)
          end
        end
      end
    end
  end
end
