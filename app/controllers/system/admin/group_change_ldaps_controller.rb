class System::Admin::GroupChangeLdapsController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
    @current='ldap'

    item = System::GroupChange.new
    item.order "created_at DESC , updated_at DESC"
    @item_latest=item.find(:first)

    item = System::GroupChange.new
    item.state = '6'
    item.order "created_at DESC , updated_at DESC"
    @item_states = item.find(:first)
    @start_at = System::GroupChangePickup.find(:first,:order=>"updated_at DESC").target_at
  end

  def find_groups
    groups = System::LdapGroup.find_one
    return groups
  end

  def index
    case params[:do]
    when 'preview'
      return _preview
    when 'create'
      return _create
    end

    item = System::LdapTemporary.new
    item.page params[:page], params[:limit]
    item.order params[:sort], 'version DESC'
    @items = item.find(:all, :group => :version)

    _index @items
  end

  def show
    tmp = System::LdapTemporary.new
    tmp.and :version, params[:id]
    tmp.and :parent_id, 0
    tmp.and :data_type, 'group'
    @groups = tmp.find(:all, :order => :code)

    case params[:do]
    when 'synchro'
      return _synchro
    when 'match'
      return _match
    end
  end

  def destroy
    System::LdapTemporary.delete_all(['version = ?', params[:id]])
    flash[:notice] = "中間データを削除しました［ version: #{params[:id]} ］"
    redirect_to url_for(:action => :index)
  end

private
  def _preview
    @groups = find_groups
  rescue ActiveLdap::LdapError::AdminlimitExceeded
    raise 'Error: LDAP通信時間超過'
  rescue
    raise 'Error: LDAP Error'
  end

  def _create
    require 'time'

    time_base = Time.parse("1970-01-01T00:00:00Z")
    @version = (Time.now - time_base).to_i
    @groups  = find_groups

    sort_no = 0
    next_sort_no = Proc.new do
      sort_no += 10
    end

    @groups.each do |d|
      next unless d.synchro_target?
      d_db = System::LdapTemporary.new({
        :parent_id => 0,
        :version   => @version,
        :data_type => 'group',
        :code      => d.db_value(:code),
        :sort_no   => next_sort_no.call,
        :name      => d.db_value(:name),
        :name_en   => d.db_value(:name_en),
        :email     => d.db_value(:email),
      })
      d_db.save

      d.children.each do |s|
        s_db = System::LdapTemporary.new({
          :parent_id => d_db.id,
          :version   => @version,
          :data_type => 'group',
          :code      => s.db_value(:code),
          :sort_no   => next_sort_no.call,
          :name      => s.db_value(:name),
          :name_en   => s.db_value(:name_en),
          :email     => s.db_value(:email),
        })
        s_db.save

        s.users.each do |u|
          next unless u.synchro_target?
          u_db = System::LdapTemporary.new({
            :parent_id => s_db.id,
            :version   => @version,
            :data_type => 'user',
            :code      => u.get('uid'),
            :name      => u.get('cn'),
            :name_en   => u.get('cn;lang-en'),
            :email     => u.get('mail'),
            :offitial_position => u.get('title'),
            :assigned_job =>  u.get('employeeType'),
            :sort_no      =>  u.get('departmentNumber'),
#            :kana         =>  u.get('departmentNumber'),
          })
          u_db.save
        end
      end
    end

    flash[:notice] = "中間データを作成しました［ version: #{@version} ］"
    redirect_to url_for(:action => :show, :id => @version)

  rescue ActiveLdap::LdapError::AdminlimitExceeded
    raise 'Error: LDAP通信時間超過'
  rescue
    raise 'Error: LDAP Error'
  end


  def quote(val)
    System::GroupHistory.connection.quote(val)
  end

  def _match
    tmp = System::LdapTemporary.new
    tmp.and :version, params[:id]
    tmp.and :parent_id, 0
    tmp.and :data_type, 'group'
    @groups = tmp.find(:all, :order => :code)

    @version = params[:id]
    @errors_g  = []

    rtn = System::GroupChange.check_sequence(@item_latest,'ldap')
    if rtn == false
        flash[:notice] = "実行順序が違っています。"
        redirect_to system_group_changes_path
        return
    end

    target  = System::GroupChangePickup.find(:first ,:order=>"updated_at DESC")
    if target.blank?
        flash[:notice] = "抽出対象日が設定されていません。"
        redirect_to system_group_changes_path
    end
    target_d  = target.target_at.strftime('%Y-%m-%d 00:00:00')
    target_before_d  = (target.target_at-1).strftime('%Y-%m-%d %H:%M:%S')

    l2_cond = "version=#{@version} and data_type='group' and parent_id=0 "
    ldap_groups = System::LdapTemporary.find(:all , :conditions=>l2_cond ,:order=>"code")
    if ldap_groups.blank?
      messages = ["LDAPの部局データが見つかりません。データの取得に失敗がないか、確認してください。"]
      flash[:notice] = messages
      redirect_to url_for(:action => :show)
    end
    g2_cond = "state='enabled' and level_no = 2 and (end_at is null or end_at > '#{target_d}')"
    temp_groups = System::GroupHistoryTemporary.find(:all , :conditions=>g2_cond ,:order=>"code")
    if temp_groups.blank?
      messages = ["ＧＷの部局データが見つかりません。データの設定に失敗がないか、確認してください。"]
      flash[:notice] = messages
      redirect_to url_for(:action => :show)
    end

    ldap_i = 0
    temp_i = 0
    while ( ldap_i < ldap_groups.size and temp_i < temp_groups.size ) do
      if ldap_groups[ldap_i].code == temp_groups[temp_i].code
        if ldap_groups[ldap_i].name == temp_groups[temp_i].name
          # 一致
          ldap_groups[ldap_i].match = '10'
          ldap_groups[ldap_i].save(false)
          temp_groups[temp_i].version_id = 10
          temp_groups[temp_i].sort_no = ldap_groups[ldap_i].sort_no
          temp_groups[temp_i].save(false)

            l3_cond = "version=#{@version} and data_type='group' and parent_id=#{ldap_groups[ldap_i].id} "
            ldap3_groups = System::LdapTemporary.find(:all , :conditions=>l3_cond ,:order=>"code")
            g3_cond = "state='enabled' and  (end_at is null or end_at > '#{target_d}') and parent_id=#{temp_groups[temp_i].id}"
            temp3_groups = System::GroupHistoryTemporary.find(:all , :conditions=>g3_cond ,:order=>"code")
            ldap3_i = 0
            temp3_i = 0
            while ( ldap3_i < ldap3_groups.size and temp3_i < temp3_groups.size ) do

              if ldap3_groups[ldap3_i].code.to_s=='002710'

                  ldap3_i = ldap3_i + 1
                next
              end
              if ldap3_groups[ldap3_i].code.to_s=='360300'

                  ldap3_i = ldap3_i + 1
                next
              end
              if ldap3_groups[ldap3_i].code.to_s=='517100'

                  ldap3_i = ldap3_i + 1
                next
              end
              if ldap3_groups[ldap3_i].code+ldap3_groups[ldap3_i].name == temp3_groups[temp3_i].code+temp3_groups[temp3_i].name

                  ldap3_groups[ldap3_i].match = '10'
                  ldap3_groups[ldap3_i].save(false)
                  temp3_groups[temp3_i].version_id = 10
                  temp3_groups[temp3_i].sort_no = ldap3_groups[ldap3_i].sort_no.to_i
                  temp3_groups[temp3_i].save(false)
                  #
                  ldap3_i = ldap3_i + 1
                  temp3_i = temp3_i + 1
                else
                if ldap3_groups[ldap3_i].code+ldap3_groups[ldap3_i].name < temp3_groups[temp3_i].code+temp3_groups[temp3_i].name

                  ldap3_groups[ldap3_i].match = '30'
                  ldap3_groups[ldap3_i].save(false)
                  @errors_g << "ldap3　#{ldap3_groups[ldap3_i].code}#{ldap3_groups[ldap3_i].name} "
                  ldap3_i = ldap3_i + 1
                else

                  temp3_groups[temp3_i].version_id = 30
                  temp3_groups[temp3_i].save(false)
                  @errors_g << "SYSTEM  #{temp3_groups[temp3_i].code}#{temp3_groups[temp3_i].name}"
                  temp3_i = temp3_i + 1
                end
              end
            end
            while ldap3_i < ldap3_groups.size do

              if ldap3_groups[ldap3_i].code.to_s=='002710'
                  ldap3_i = ldap3_i + 1
                next
              end
              if ldap3_groups[ldap3_i].code.to_s=='360300'
                  ldap3_i = ldap3_i + 1
                next
              end
              if ldap3_groups[ldap3_i].code.to_s=='517100'
                  ldap3_i = ldap3_i + 1
                next
              end
              ldap3_groups[ldap3_i].match = '40'
              ldap3_groups[ldap3_i].save(false)
              @errors_g << "LDAP　#{ldap3_groups[ldap3_i].code}#{ldap3_groups[ldap3_i].name} "
              ldap3_i = ldap3_i + 1
            end
            while temp3_i < temp3_groups.size do
              temp3_groups[temp3_i].version_id = 40
              temp3_groups[temp3_i].save(false)
              @errors_g << "SYSTEM  #{temp3_groups[temp3_i].code}#{temp3_groups[temp3_i].name}"
              temp3_i = temp3_i + 1
            end
          ldap_i = ldap_i + 1
          temp_i = temp_i + 1
        else
          @errors_g << "LDAP　#{ldap_groups[ldap_i].code}#{ldap_groups[ldap_i].name} SYSTEM  #{temp_groups[temp_i].code}#{temp_groups[temp_i].name}"
          ldap_groups[ldap_i].match = '20'
          ldap_groups[ldap_i].save(false)
          temp_groups[temp_i].version_id = 20
          temp_groups[temp_i].sort_no = ldap_groups[ldap_i].sort_no.to_i
          temp_groups[temp_i].save(false)
          ldap_i = ldap_i + 1
          temp_i = temp_i + 1
        end
      else
        if ldap_groups[ldap_i].code.to_s < temp_groups[temp_i].code.to_s
          ldap_groups[ldap_i].match = '30'
          ldap_groups[ldap_i].save(false)
          @errors_g << "LDAP　#{ldap_groups[ldap_i].code}#{ldap_groups[ldap_i].name} "
          ldap_i = ldap_i + 1
        else
          temp_groups[temp_i].version_id = 30
          temp_groups[temp_i].save(false)
          @errors_g << "SYSTEM  #{temp_groups[temp_i].code}#{temp_groups[temp_i].name}"
          temp_i = temp_i + 1
        end
      end
    end
    while ldap_i < ldap_groups.size do
      ldap_groups[ldap_i].match = '40'
      ldap_groups[ldap_i].save(false)
      @errors_g << "LDAP　#{ldap_groups[ldap_i].code}#{ldap_groups[ldap_i].name} "
      ldap_i = ldap_i + 1
    end
    while temp_i < temp_groups.size do
      temp_groups[temp_i].version_id = 40
      temp_groups[temp_i].save(false)
      @errors_g << "SYSTEM  #{temp_groups[temp_i].code}#{temp_groups[temp_i].name}"
      temp_i = temp_i + 1
    end
    if @errors_g.blank?
      messages = ["所属情報はすべて一致しました。同期処理を実行してください。"]
      flash[:notice] = messages
    else
      messages = ["所属情報に不一致が見つかりました。LDAPの内容を確認してください。問題なければ、同期処理を実行してください。"]
      messages.push @errors_g
      flash[:notice] = messages.join('<br />')
    end
    redirect_to url_for(:action => :show ,:do=>'before_synchro')
  end

  def _synchro
    @version = params[:id]
    @errors  = []

    target  = System::GroupChangePickup.find(:first ,:order=>"updated_at DESC")
    if target.blank?
        flash[:notice] = "抽出対象日が設定されていません。"
        redirect_to system_group_changes_path
    end
    target_d  = target.target_at.strftime('%Y-%m-%d 00:00:00')
    target_before_d  = (target.target_at-1).strftime('%Y-%m-%d %H:%M:%S')

    System::GroupHistoryTemporary.update_all("end_at = '#{target_before_d}'" , "ldap=1")
    System::GroupHistoryTemporary.update_all("state = 'disabled'" , "ldap=1")
    System::GroupHistoryTemporary.update_all("ldap_version = NULL" , "ldap=1")
    System::GroupHistoryTemporary.update_all("ldap=0")

    System::UserTemporary.update_all("state = 'disabled'" , "ldap=1")
    System::UserTemporary.update_all("ldap_version = NULL" , "ldap=1")
    System::UserTemporary.update_all("ldap=0")

    System::UsersGroupHistoryTemporary.update_all("end_at='#{target_before_d}'")

    group_sort_no = 0
    group_next_sort_no = Proc.new do
      group_sort_no = group_sort_no + 10
    end

    @groups.each do |d|
      cond = "parent_id=1 and level_no=2 and code='#{d.code}'"
      order = "start_at DESC"
      group_h = System::GroupHistoryTemporary.find(:first,:conditions=>cond,:order=>order)
      if group_h.blank?
        group_h = System::GroupHistoryTemporary.new
        group_h.start_at     = target_d
        group_h.created_at   = Core.now
      end

      group_h.parent_id    = 1
      group_h.state        = 'enabled'
      group_h.updated_at   = Core.now
      group_h.name         = d.name
      group_h.name_en      = d.name_en
      group_h.email        = d.email
      group_h.level_no     = 2
      group_h.sort_no      = group_next_sort_no.call
      group_h.ldap_version = @version

  		group_h.ldap         = 1
      group_h.code         = d.code
      group_h.version_id   = 0
      group_h.end_at       = nil

      unless group_h.save
        if group_h.id.to_i==0
          @errors << "group_h2-n : #{d.code.to_s}-#{d.name}"
        else
          @errors << "group_h2-u : #{d.code.to_s}-#{d.name}"
        end
      end

      d.children.each do |s|
        if s.code.to_s=='002710'
          next
        end
        if s.code.to_s=='360300'
          next
        end
        if s.code.to_s=='517100'
          next
        end
        s_cond  = "parent_id=#{group_h.id} and level_no=3 and code='#{s.code}'"
        s_order = "start_at DESC"
        c_group_h = System::GroupHistoryTemporary.find(:first,:conditions=>s_cond,:order=>s_order)
        if c_group_h.blank?
          c_group_h             = System::GroupHistoryTemporary.new
          c_group_h.start_at    = target_d
          c_group_h.created_at  = Core.now
        end
        c_group_h.parent_id     = group_h.id
        c_group_h.state         = 'enabled'
        c_group_h.updated_at    = Core.now
        c_group_h.name          = s.name
        c_group_h.name_en       = s.name_en
        c_group_h.email         = s.email
        c_group_h.level_no      = 3
        c_group_h.sort_no       = group_next_sort_no.call
        c_group_h.ldap_version  = @version

  		  c_group_h.ldap          = 1
        c_group_h.version_id    = 0
        c_group_h.code          = s.code.to_s
        c_group_h.end_at        = nil

        unless c_group_h.save
          if c_group_h.id.to_i==0
            @errors << "group_h3-n : #{s.code.to_s} - #{s.name}"
          else
            @errors << "group_h3-u : #{s.code.to_s} - #{s.name}"
          end
        end

        s.users.each do |u|
          cond = "code='#{u.code}'"
          user = System::UserTemporary.find(:first,:conditions=>cond)
          if user.blank?
            user                  = System::UserTemporary.new
            user.created_at       = Core.now
            user.auth_no          = 3
          end
          user.updated_at         = Core.now
          user.state              = 'enabled'
          user.ldap               = 1
          user.name               = u.name
          user.name_en            = u.name_en
          user.email              = u.email
          user.ldap_version       = @version
          user.code               = u.code
          user.offitial_position  = u.offitial_position
          user.assigned_job       = u.assigned_job
          user.sort_no            = u.sort_no

          if user.save
            user_group_h = System::UsersGroupHistoryTemporary.clear_group_historty_relations(user,c_group_h.id)
            if user_group_h==nil
              user_group_h            = System::UsersGroupHistoryTemporary.new
              user_group_h.user_id    = user.id
              user_group_h.group_id   = c_group_h.id
              user_group_h.user_code  = user.code
              user_group_h.group_code = c_group_h.code
              user_group_h.job_order  = 0
              user_group_h.start_at   = target_d
              user_group_h.save
            end
          else
            if user.id.to_i==0
              @errors << "user-n : #{u.code} - #{u.name}"
            else
              @errors << "user-u : #{u.code} - #{u.name}"
            end
          end

        end ##/users
      end ##/sections
    end ##/departments

    items = System::UsersGroupHistoryTemporary.find(:all,:order=>"user_code")
    items.each do |ug|
      user = System::UserTemporary.find(ug.user_id)
      next if user.blank?
      if user.ldap==0 and user.state=='enabled'
        ug.end_at = nil
        ug.save
      end
    end

    g_cond  = " state='enabled' and ldap=1 and level_no > 1"
    g_order = " sort_no"
    groups  = System::GroupHistoryTemporary.find(:all ,:conditions=>g_cond ,:order=>g_order)
    unless groups.blank?
      groups.each do |g|
        check_user_code = g.code.to_s+"_0"
        check_user_name = g.name.to_s+"予定"

        ug_cond     = " group_id=#{g.id} and LENGTH(user_code)=8 and right(user_code,2)='_0' "
        ug_order    = " user_code "
        group_users = System::UsersGroupHistoryTemporary.find(:all , :conditions=>ug_cond , :order=>ug_order)
        if group_users.blank?
          user       = create_user(check_user_code,check_user_name)
          unless user.blank?
            user_group = create_user_group(user , g ,target_d)
            if user_group.blank?
              @errors << "users_group : #{group_users[0].user_code}-#{g.code} create fail "
            end
          end
        else
          if group_users.size==1
            user  = System::UserTemporary.find_by_id(group_users[0].user_id)
            if user.blank?
              @errors << "user : #{group_users[0].user_code} not found "
            else
              if group_users[0].user_code.to_s==check_user_code
                if user.name.to_s==check_user_name
                else
                  user.name = check_user_name
                  user.save
                end
              else
                user.code     = check_user_code
                user.name     = check_user_name
                user.password = check_user_code.to_s + 'pass'
                user.save
                System::UsersGroupHistoryTemporary.update_all(" user_code='#{check_user_code}' " , " user_code='#{group_users[0].user_code}' ")
              end
            end
          else
            hit = 0
            group_users.each do |gu|
              if gu.user_code.to_s == check_user_code
                hit = 1
                break
              end
            end
            if hit==0
            else
              user  = System::UserTemporary.find_by_id(group_users[0].user_id)
              if user.blank?
                @errors << "user : #{group_users[0].user_code} not found "
              else
                user.name = check_user_name
                user.save
              end
            end
          end
        end
      end
    end

    if @errors.size > 0
      flash[:notice] = 'Error: <br />' + @errors.join('<br />')
    else
      System::GroupChange.make_record(@item_states,'ldap')
      flash[:notice] = '同期処理が完了しました'
    end
    redirect_to url_for(:action => :show)
  end

  def create_user(code , name)
      user                    = System::UserTemporary.new
      user.created_at         = Core.now
      user.auth_no            = 3
      user.updated_at         = Core.now
      user.state              = 'enabled'
      user.ldap               = 0
      user.name               = name
      user.name_en            = nil
      user.email              = nil
      user.ldap_version       = @version
      user.code               = code
      user.offitial_position  = nil
      user.assigned_job       = nil
      user.sort_no            = nil
      user.password           = code.to_s + 'pass'

      if user.save
        return user
      else
        return nil
      end
  end
  def create_user_group(user , g ,target_d)
      user_group_h            = System::UsersGroupHistoryTemporary.new
      user_group_h.user_id    = user.id
      user_group_h.group_id   = g.id
      user_group_h.user_code  = user.code
      user_group_h.group_code = g.code
      user_group_h.job_order  = 0
      user_group_h.start_at   = target_d
      if user_group_h.save
        return user_group_h
      else
        return nil
      end
  end

  ## ------ version 1 ------ ##

  def _test
    @groups = System::LdapGroup.find_all_as_tree
    @users = System::LdapUser.find_all_as_tree
  end

  def _synchronize
    rels = []
    System::User.find(:all, :conditions => {:ldap => 0}).each do |user|
      rels << {
        :user_id => user.id,
        :groups  => user.groups.collect{|i| i.id}
      }
    end

    _synchronize_groups
    _synchronize_users

    rels.each do |rel|
      rel[:groups].each do |group_id|
        System::UsersGroup.create({
          :user_id  => rel[:user_id],
          :group_id => group_id,
        })
      end
    end

    flash[:notice] = '同期処理が完了しました'
    redirect_to url_for(:action => :show)
  end

  def _synchronize_groups
    quote = Proc.new do |val|
      System::Group.connection.quote(val)
    end

    @groups = System::LdapGroup.find_all_as_tree

    System::Group.destroy_all('id != 1')

    @groups.each do |dep|
      sql = "INSERT INTO #{System::Group.table_name} (" +
        " id, parent_id, state, created_at, updated_at, level_no, name, name_en, email" +
        " ) VALUES (" +
        " #{quote.call(dep[:id])}" +
        " ,#{quote.call(dep[:parent_id])}" +
        " ,'enabled'" +
        " ,#{quote.call(Core.now)}" +
        " ,#{quote.call(Core.now)}" +
        " ,#{quote.call(dep[:level_no])}" +
        " ,#{quote.call(dep[:name])}" +
        " ,#{quote.call(dep[:name_en])}" +
        " ,#{quote.call(dep[:email])}" +
        ")"
      System::Group.connection.execute(sql) unless dep[:duplicated]

      dep[:sections].each do |sec|
        sql = "INSERT INTO #{System::Group.table_name} (" +
          " id, parent_id, state, created_at, updated_at, level_no, name, name_en, email" +
          " ) VALUES (" +
          " #{quote.call(sec[:id])}" +
          " ,#{quote.call(sec[:parent_id])}" +
          " ,'enabled'" +
          " ,#{quote.call(Core.now)}" +
          " ,#{quote.call(Core.now)}" +
          " ,#{quote.call(sec[:level_no])}" +
          " ,#{quote.call(sec[:name])}" +
          " ,#{quote.call(sec[:name_en])}" +
          " ,#{quote.call(sec[:email])}" +
          ")"
        System::Group.connection.execute(sql) unless sec[:duplicated]
      end
    end
  end

  def _synchronize_users
    quote = Proc.new do |val|
      System::User.connection.quote(val)
    end

    @users = System::LdapUser.find_all_as_tree

    System::User.destroy_all('ldap = 1')

    @users.each do |user|
      next if user[:duplicated]

      sql = "INSERT INTO #{System::User.table_name} (" +
        " id, state, created_at, updated_at, ldap, name, email" +
        " ) VALUES (" +
        " #{quote.call(user[:id])}" +
        " ,'enabled'" +
        " ,#{quote.call(Core.now)}" +
        " ,#{quote.call(Core.now)}" +
        " ,'1'" +
        " ,#{quote.call(user[:name])}" +
        " ,#{quote.call(user[:email])}" +
        ")"
      System::User.connection.execute(sql)

      System::UsersGroup.create({
        :user_id => user[:id],
        :group_id => user[:group_id],
      })
    end
  end
end
