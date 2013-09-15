class System::Admin::LdapGroupsController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
    if params[:parent] == '0'
      @parent = nil
    else
      @parent = params[:parent]
    end
  end

  def index
    if @parent
      @items = System::LdapUser.find_sections(@parent)
    else
      @items = System::LdapGroup.find_departments
    end

    _index @items
  end

  def show
    return _test if params[:do] == 'test'
    return _synchronize if params[:do] == 'synchronize'
  end

private
  def _test
    @groups = System::LdapGroup.find_all_as_tree
    @users = System::LdapUser.find_all_as_tree(@groups)
  end

  def _synchronize
    rels = []
    System::User.find(:all, :conditions => {:ldap => 0}).each do |user|
      rels << {
        :user_id => user.id,
        :groups  => user.groups.collect{|i| i.id}
      }
    end
    _create_versions
    _synchronize_groups
    _synchronize_users(@groups)
    flash[:notice] = '同期処理が完了しました'
    redirect_to url_for(:action => :show)
  end

  def _create_versions
      _item = System::GroupVersion.new({
        :version  => Time.now.year ,
        :start_at => Time.now ,
        })
      _item.save
      system_log.add(:item => _item, :action => 'create')
    @group_version_last = System::GroupVersion.find(:last)
  end

  def _synchronize_users(_group)
    @users = System::LdapUser.find_all_as_tree(_group)
    @users.each do |user|
      next if user[:duplicated]

      _item = System::User.new({
          :state => 'enabled' ,
          :created_at => Core.now ,
          :updated_at => Core.now ,
          :code => user[:code] ,
          :ldap => '1' ,
          :name => user[:name] ,
          :name_en => user[:name_en] ,
          :email => user[:email]
        })
      _item.save
      system_log.add(:item => _item, :action => 'create')
      _user = System::User.find(:first , :conditions=>"code = '#{user[:code]}'" ,:order => "id DESC")
      _group_condition = "code='#{user[:group_code]}' and version_id = '#{@group_version_last.id}'"
      _group1 = System::Group.find(:first , :conditions => _group_condition , :order => "id DESC")
      if _group1.blank?
        pp _user
      end
      if _group1.blank?
      else
        System::UsersGroup.create({
          :user_id => _user.id ,
          :group_id => _group1.id ,
        })
      end
    end
  end

  def _synchronize_groups
    _dep_parent = System::Group.find(:first, :conditions => "code=1")
    _dep_parent_id = _dep_parent.id
    @groups = System::LdapGroup.find_all_as_tree
    @groups.each do |dep|
      next if dep[:duplicated]

      _item = System::Group.new({
          :parent_id => _dep_parent_id ,
          :state => 'enabled' ,
          :created_at => Core.now ,
          :updated_at => Core.now ,
          :level_no => dep[:level_no] ,
          :version_id => @group_version_last.id ,
          :code => dep[:code] ,
          :name => dep[:name] ,
          :name_en => dep[:name_en] ,
          :email => dep[:email]
        })
      _item.save
      system_log.add(:item => _item, :action => 'create')
      _sec_parent = System::Group.find(:last ,:conditions=>"level_no='#{dep[:level_no]}' and code='#{dep[:code]}'" )
      _history = System::GroupHistory.new({
          :created_at => Core.now ,
          :updated_at => Core.now ,
          :current_version_id => @group_version_last.id ,
          :current_group_id => _sec_parent.id,
          :remarks => 'Create BY LDAP syncronized',
          :merge_count => 0,
          :action => nil
        })
      _history.save
      system_log.add(:item => _history, :action => 'create')
      _sec_parent_id = _sec_parent.id

      dep[:sections].each do |sec|
        next if sec[:duplicated]
        _item = System::Group.new({
            :parent_id => _sec_parent_id ,
            :state => 'enabled' ,
            :created_at => Core.now ,
            :updated_at => Core.now ,
            :version_id => @group_version_last.id ,
            :level_no => sec[:level_no] ,
            :code => sec[:code] ,
            :name => sec[:name] ,
            :name_en => sec[:name_en] ,
            :email => sec[:email]
          })
        _item.save
        system_log.add(:item => _item, :action => 'create')
        _section = System::Group.find(:last ,:conditions=>"level_no='#{sec[:level_no]}' and code='#{sec[:code]}'" )
        _history = System::GroupHistory.new({
            :created_at => Core.now ,
            :updated_at => Core.now ,
            :current_version_id => @group_version_last.id ,
            :current_group_id => _section.id,
            :remarks => 'Create BY LDAP syncronized',
            :merge_count => 0,
            :action => nil
          })
        _history.save
        system_log.add(:item => _history, :action => 'create')
      end
    end
  end
end
