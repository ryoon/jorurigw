class System::Admin::GroupHistoriesController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
    @action = params[:action]
    id      = params[:parent] == '0' ? 1 : params[:parent]
    @parent = System::GroupHistory.new.find(id)
  end

  def index
    if params[:do] == 'current'
      _pickup_current
    end
    item = System::GroupHistory.new #.readable
    item.parent_id = @parent.id
    item.state = 'enabled'
    item.page  params[:page], params[:limit]
    item.order params[:sort], :code
    @items = item.find(:all)
    _index @items
  end

  def show
    @item = System::GroupHistory.new.find(params[:id])
    return error_auth unless @item.readable?
    _show @item
  end

  def new
    @item = System::GroupHistory.new({
      :state      => 'enabled',
      :parent_id  => @parent.id,
    })
  end

  def create
    @item = System::GroupHistory.new(params[:item])
    @item.parent_id  = @parent.id
    @item.level_no   = @parent.level_no.to_i + 1
    _create @item
  end

  def edit
    @item = System::GroupHistory.new.find(params[:id])
    return error_auth unless @item.readable?
  end

  def update
    @item = System::GroupHistory.new.find(params[:id])
    @item.attributes = params[:item]
  end

  def csvput
    return if params[:item].nil?
    par_item = params[:item]
    nkf_options = case par_item[:nkf]
        when 'utf8'
          '-w'
        when 'sjis'
          '-s'
        end
    case par_item[:csv]
    when 'put'
      filename = "system_group_histories_#{par_item[:nkf]}.csv"
      g_order="level_no ASC , code ASC "
      items = System::Group.find(:all,:order=>g_order)
      if items.blank?
      else
        file = Gw::Script::Tool.ar_to_csv(items)
        send_download "#{filename}", NKF::nkf(nkf_options,file)
      end
    else
    end
  end

  def csvup
    flash[:notice]=''
    return if params[:item].nil?
    par_item = params[:item]
    case par_item[:csv]
    when 'up'
      if par_item.nil? || par_item[:nkf].nil? || par_item[:file].nil?
        flash[:notice] = 'ファイル名を入力してください'
      else
        upload_data = par_item[:file]
        f = upload_data.read
        nkf_options = case par_item[:nkf]
        when 'utf8'
          '-w -W'
        when 'sjis'
          '-w -S'
        end
        file =  NKF::nkf(nkf_options,f)
        if file.blank?
        else
          System::GroupHistory.truncate_table
          s_to = Gw::Script::Tool.import_csv(file, "system_group_histories")
        end
        redirect_to system_group_histories_path(0)
      end
    else
    end
  end

  def csvadd
    flash[:notice]=''
    return if params[:item].nil?
    par_item = params[:item]
    case par_item[:csv]
    when 'up'
      if par_item.nil? || par_item[:nkf].nil? || par_item[:file].nil?
        flash[:notice] = 'ファイル名を入力してください'
      else
        upload_data = par_item[:file]
        f = upload_data.read
        nkf_options = case par_item[:nkf]
        when 'utf8'
          '-w -W'
        when 'sjis'
          '-w -S'
        end
        file =  NKF::nkf(nkf_options,f)
        if file.blank?
        else
          s_to = Gw::Script::Tool.import_csv(file, "system_group_histories")
        end
        redirect_to system_group_histories_path(0)
      end
    else
    end
  end

private

  def _pickup_current
    System::Group.transaction do
      begin
        System::Group.truncate_table
        g_cond = "state='enabled' and (end_at ='0000-00-00 00:00:00' or end_at IS NULL)"
        groups = System::GroupHistory.find(:all,:conditions=>g_cond,:order=>'id')
        groups.each do |g|
          new_g = System::Group.new
          new_g.id            = g.id
          new_g.parent_id     = g.parent_id
          new_g.state         = g.state
          new_g.created_at    = g.created_at
          new_g.updated_at    = g.updated_at
          new_g.level_no      = g.level_no
          new_g.version_id    = g.version_id
          new_g.code          = g.code
          new_g.name          = g.name
          new_g.name_en       = g.name_en
          new_g.email         = g.email
          new_g.start_at      = g.start_at
          new_g.end_at        = g.end_at
          new_g.sort_no       = g.sort_no
          new_g.ldap_version  = g.ldap_version
          new_g.ldap          = g.ldap
          new_g.save!
        end
        System::UsersGroup.truncate_table
        ug_cond = "job_order = 0 and (end_at ='0000-00-00 00:00:00' or end_at IS NULL)"
        ugs = System::UsersGroupHistory.find(:all,:conditions=>ug_cond,:order=>'rid')
        ugs.each do |ug|
          new_ug = System::UsersGroup.new
          new_ug.rid = ug.rid
          new_ug.created_at = ug.created_at
          new_ug.updated_at = ug.updated_at
          new_ug.user_id = ug.user_id
          new_ug.group_id = ug.group_id
          new_ug.job_order = ug.job_order
          new_ug.start_at = ug.start_at
          new_ug.end_at = ug.end_at
          new_ug.user_code = ug.user_code
          new_ug.group_code = ug.group_code
          new_ug.save!
        end
      rescue ActiveRecord::StatementInvalid
      end
    end
    return
  end

end
