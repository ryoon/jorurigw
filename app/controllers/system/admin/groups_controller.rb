class System::Admin::GroupsController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
    @action = params[:action]
    id      = params[:parent] == '0' ? 1 : params[:parent]
    @parent = System::Group.new.find(id)
  end

  def index
    item = System::Group.new
    item.parent_id = @parent.id

    item.page  params[:page], params[:limit]

    order = "state DESC,sort_no,code"
    @items = item.find(:all,:order=>order)
    _index @items
  end

  def show
    @item = System::Group.new.find(params[:id])

    _show @item
  end

  def new
    @item = System::Group.new({
        :parent_id    =>  @parent.id,
        :state        =>  'enabled',
        :level_no     =>  @parent.level_no.to_i + 1,
        :version_id   =>  @parent.version_id.to_i,
        :start_at     =>  Time.now.strftime("%Y-%m-%d 00:00:00"),
        :sort_no      =>  @parent.sort_no.to_i ,
        :ldap_version =>  nil,
        :ldap         =>  0
    })
  end
  def create

    @item = System::Group.new(params[:item])
    @item.parent_id     = @parent.id
    @item.level_no      = @parent.level_no.to_i + 1
    @item.version_id    = @parent.version_id.to_i
    @item.ldap_version  = nil
    @item.ldap          = 0
    _create @item
  end

  def update
    @item = System::Group.new.find(params[:id])
    if params[:item]['state'] == 'enabled'
      params[:item]['end_at'] = nil
    else
      if params[:item]['end_at'].blank? or params[:item]['end_at'] == "0000-00-00 00:00:00"

        params[:item]['end_at'] = Time.now.strftime("%Y-%m-%d 00:00:00")
      else
        if params[:item]['end_at'] < Time.now.strftime("%Y-%m-%d 00:00:00")
          params[:item]['state'] = 'disabled'
        end
      end
    end
    @item.attributes = params[:item]
    _update @item
  end

  def destroy
    @item = System::Group.new.find(params[:id])
    ug_cond="group_id=#{@item.id}"
    user_count = System::UsersGroup.count(:all,:conditions=>ug_cond)
    if user_count==0
      @item.state  = 'disabled'
      @item.end_at = Time.now.strftime("%Y-%m-%d 00:00:00")
      _update @item

    else
      flash[:notice] = flash[:notice]||'ユーザーが登録されているため、削除できません。'
      redirect_to :action=>'index'
    end
  end

  def item_to_xml(item, options = {})
    options[:include] = [:status]
    xml = ''; xml << item.to_xml(options) do |n|
      #n << item.relation.to_xml(:root => 'relations', :skip_instruct => true, :include => [:user]) if item.relation
    end
    return xml
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
      filename = "system_groups_#{par_item[:nkf]}.csv"
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
          System::Group.truncate_table
          s_to = Gw::Script::Tool.import_csv(file, "system_groups")
        end

        redirect_to system_groups_path
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

          s_to = Gw::Script::Tool.import_csv(file, "system_groups")
        end

        redirect_to system_groups_path
      end
    else
    end
  end
end
