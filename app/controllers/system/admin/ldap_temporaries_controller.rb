class System::Admin::LdapTemporariesController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
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
            :sort_no   => u.get('departmentNumber'),
            :kana      => u.get('cn;lang-ja'),
            :name      => u.get('cn'),
            :name_en   => u.get('cn;lang-en'),
            :email     => u.get('mail'),
            :offitial_position => u.get('title'),
            :assigned_job =>  u.get('employeeType')

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

  def _synchro
    @version = params[:id]
    @errors  = []
    tmp = System::LdapTemporary.new
    tmp.and :version, params[:id]
    tmp.and :parent_id, 0
    tmp.and :data_type, 'group'

    @groups = tmp.find(:all, :order => :code)

    System::Group.update_all("end_at = '#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}'","ldap=1")
    System::Group.update_all("state = 'disabled'" , "ldap=1")
    System::Group.update_all("ldap_version = NULL")

    System::GroupHistory.update_all("end_at = '#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}'" , "ldap=1")
    System::GroupHistory.update_all("state = 'disabled'" , "ldap=1")
    System::GroupHistory.update_all("ldap_version = NULL")
    System::GroupHistory.update_all("ldap=0")

    System::User.update_all("state = 'disabled'" , "ldap=1")
    System::User.update_all("ldap_version = NULL")
    System::User.update_all("ldap=0")

    System::UsersGroupHistory.update_all("end_at='#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}'" , "end_at is NULL")

    group_sort_no = 0
    group_next_sort_no = Proc.new do
      group_sort_no = group_sort_no + 10
    end

    @groups.each do |d|
      cond = "parent_id=1 and level_no=2 and code='#{d.code}' "
      order = "code"
      group = System::Group.find(:first,:conditions=>cond,:order=>order)
      if group.blank?
        group = System::Group.new
      end

      group.parent_id    = 1
      group.state        = 'enabled'
      group.updated_at   = Core.now
      group.name         = d.name
      group.name_en      = d.name_en
      group.email        = d.email
      group.level_no     = 2
      group.sort_no      = group_next_sort_no.call

      group.ldap_version = @version

  		group.ldap = 1
      group.code          = d.code
      group.version_id    = 0
      group.end_at        = nil

      if group.id
        @errors << "group2-u : #{d.code.to_s}-#{d.name}" unless group.save
      else
        group.start_at     = Date.today
        group.created_at   = Core.now
    		@errors << "group2-n : #{d.code.to_s}-#{d.name}" unless group.save
      end

      group_h = System::GroupHistory.find(:first,:conditions=>cond,:order=>order)
      if group_h.blank?
        group_h = System::GroupHistory.new
      end

      group_h.parent_id    = 1
      group_h.state        = 'enabled'
      group_h.updated_at   = Core.now
      group_h.name         = d.name
      group_h.name_en      = d.name_en
      group_h.email        = d.email
      group_h.level_no     = 2
      group_h.sort_no      = group.sort_no

      group_h.ldap_version = @version

  		group_h.ldap = 1
      group_h.code          = d.code
      group_h.version_id    = 0
      group_h.end_at        = nil

      if group_h.id
        @errors << "history2-u : #{d.code.to_s}-#{d.name}" unless group_h.save
      else
        group_h.start_at     = Date.today
        group_h.created_at   = Core.now
    		@errors << "history2-n : #{d.code.to_s}-#{d.name}" unless group_h.save
      end

      next unless group.save

      d.children.each do |s|
        s_cond = "parent_id=#{group.id} and level_no=3 and code='#{s.code}'"
        s_order = "code"
        c_group = System::Group.find(:first,:conditions=>s_cond,:order=>s_order)
        if c_group.blank?
          c_group = System::Group.new
        end

        c_group.parent_id    = group.id
        c_group.state        = 'enabled'
        c_group.updated_at   = Core.now
        c_group.name         = s.name
        c_group.name_en      = s.name_en
        c_group.email        = s.email
        c_group.level_no     = 3
        c_group.sort_no      = group_next_sort_no.call

        c_group.ldap_version = @version

  		  c_group.ldap = 1
        c_group.version_id    = 0
        c_group.code          = s.code.to_s
        c_group.end_at        = nil

        if c_group.id
          @errors << "group3-u : #{s.code.to_s} - #{s.name}" unless c_group.save
        else

          c_group.start_at     = Date.today
          c_group.created_at   = Core.now
          @errors << "group3-n : #{s.code.to_s} - #{s.name}" unless c_group.save
        end

        cond_h = "parent_id=#{group_h.id} and level_no=3 and code='#{s.code}'"
        order_h = "start_at DESC"
        c_group_h = System::GroupHistory.find(:first,:conditions=>cond_h,:order=>order_h)
        if c_group_h.blank?
          c_group_h = System::GroupHistory.new
        end

        c_group_h.parent_id    = group_h.id
        c_group_h.state        = 'enabled'
        c_group_h.updated_at   = Core.now
        c_group_h.name         = s.name
        c_group_h.name_en      = s.name_en
        c_group_h.email        = s.email
        c_group_h.level_no     = 3
        c_group_h.sort_no      = c_group.sort_no

        c_group_h.ldap_version = @version

  		  c_group_h.ldap = 1
        c_group_h.version_id    = 0
        c_group_h.code          = s.code.to_s
        c_group_h.end_at        = nil

        if c_group_h.id
          unless c_group_h.save
            @errors << "history3-u : #{s.code.to_s} - #{s.name}"
            pp ['history3-u',c_group_h]
          end
        else

          c_group_h.start_at     = Date.today
          c_group_h.created_at   = Core.now
          unless c_group_h.save
            @errors << "history3-n : #{s.code.to_s} - #{s.name}"
            pp ['history3-n',c_group_h]
          end
        end

        s.users.each do |u|
          cond = "code='#{u.code}'"
          user = System::User.find(:first,:conditions=>cond)
          if user.blank?
            user = System::User.new
          end

          user.updated_at   = Core.now
          user.state        = 'enabled'
          user.ldap         = 1
          user.name         = u.name
          user.name_en      = u.name_en
          user.email        = u.email
          user.ldap_version = @version
          user.code         = u.code
          user.sort_no      = u.sort_no
          user.kana         = u.kana
          user.offitial_position  = u.offitial_position
          user.assigned_job       = u.assigned_job

          if user.id
            @errors << "user-u : #{u.code} - #{u.name}" unless user.save
            user.delete_group_relations
            user_group_h = System::UsersGroupHistory.clear_group_historty_relations(user,c_group_h.id)
          else

            user.created_at   = Core.now
            user.auth_no      = 3
            @errors << "user-n : #{u.code} - #{u.name}" unless user.save
          end

          System::UsersGroup.create({:user_id  => user.id,
            :group_id => c_group.id, :user_code => user.code,
            :group_code => c_group.code, :start_at => Core.now,
            :job_order => 0})

          if user_group_h==nil
            user_group_h = System::UsersGroupHistory.new
            user_group_h.user_id    = user.id
            user_group_h.group_id   = c_group_h.id
            user_group_h.user_code  = user.code
            user_group_h.group_code = c_group_h.code
            user_group_h.job_order  = 0
            user_group_h.start_at   = Core.now
            user_group_h.save
          end

        end ##/users
      end ##/sections
    end ##/departments

    items = System::UsersGroupHistory.find(:all,:order=>"user_code")
    items.each do |ug|
      user = System::User.find_by_id(ug.user_id)
      next if user.blank?
      if user.ldap==0 and user.state=='enabled'
        ug.end_at = nil
        ug.save
      end
    end

    if @errors.size > 0
      flash[:notice] = 'Error: <br />' + @errors.join('<br />')
    else
      flash[:notice] = '同期処理が完了しました'
    end
    redirect_to url_for(:action => :show)
  end

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
