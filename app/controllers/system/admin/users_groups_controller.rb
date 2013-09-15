class System::Admin::UsersGroupsController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
    id      = params[:parent] == '0' ? 1 : params[:parent]
    @parent = System::Group.new.find(id)
    params[:limit] = nz(params[:limit],30)
    @sort_keys = "user_code ASC"

  end

  def index

    item = System::UsersGroup.new
    item.group_id = @parent.id
    item.page  params[:page], params[:limit]

    item.order params[:sort], @sort_keys
    @items = item.find(:all)

    _index @items
  end

  def show
    @item = System::UsersGroup.new.find(params[:id])

    _show @item
  end

  def new
    @action='new'
    @item = System::UsersGroup.new({
        :job_order=>0
    })
    @group_id  = nz(params[:group_id],@parent_id)
    @user_id    = nz(params[:user_id],Site.user.id)
  end

  def create

    @item = System::UsersGroup.new(params[:item])
    _create @item
  end

  def edit
    @action='edit'
    @item = System::UsersGroup.new.find(params[:id])
    @group_id  = nz(params[:group_id],@item.group_id)
    @user_id    = nz(params[:user_id],@item.user_id)
  end

  def update
    @item = System::UsersGroup.new.find(params[:id])
    @item.attributes = params[:item]
    _update @item
  end

  def destroy
    @item = System::UsersGroup.new.find(params[:id])
    _destroy @item
  end

  def item_to_xml(item, options = {})
    options[:include] = [:user]
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
      filename = "system_users_groups_#{par_item[:nkf]}.csv"
      items = System::UsersGroup.find(:all)
      if items.blank?
      else
        file = Gw::Script::Tool.ar_to_csv(items)
        send_download "#{filename}", NKF::nkf(nkf_options,file)
      end
    else
    end
  end

  def csvup
    return if params[:item].nil?
    par_item = params[:item]
    case par_item[:csv]
    when 'up'
      raise ArgumentError, '入力指定が異常です。' if par_item.nil? || par_item[:nkf].nil? || par_item[par_item[:nkf]].nil?
      upload_data = par_item[par_item[:nkf]]
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
        System::UsersGroup.truncate_table
        s_to = Gw::Script::Tool.import_csv(file, "system_users_groups")
      end

      redirect_to system_users_groups_path
    else
    end
  end
end
