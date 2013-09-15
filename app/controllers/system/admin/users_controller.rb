class System::Admin::UsersController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
    return redirect_to(request.env['PATH_INFO']) if params[:reset]
    _search_condition
    @limits = nz(params[:limit], 30)
  end
  def _search_condition
  end

  def index

    item = System::User.new
    item.search params

    item.page   params[:page], nz(params[:limit], 30)

    item.order params[:sort], :code
    @items = item.find(:all)
    _index @items
  end

  def show
    @item = System::User.new.find(params[:id])

    _show @item
  end

  def new

    top_cond = "level_no=1"
    @top        = System::Group.find(:first,:conditions=>top_cond)
    @group_id = @top.id
    @item = System::User.new({
      :state      =>  'enabled',
      :ldap       =>  '0'
    })
  end

  def create

    @item = System::User.new(params[:item])
    @item.id = params[:item]['id']

    options={
      :after_process=>Proc.new{
        if params[:ug]
            ugr = System::UsersGroup.new
            ugr.user_id   = @item.id
            ugr.group_id  = params[:ug]['group_id']
            ugr.job_order = params[:ug]['job_order']
            ugr.start_at  = params[:ug]['start_at']
            ugr.end_at    = params[:ug]['end_id']
          if ugr.save
            ugh = System::UsersGroupHistory.new
            ugh.user_id   = @item.id
            ugh.group_id  = params[:ug]['group_id']
            ugh.job_order = params[:ug]['job_order']
            ugh.start_at  = params[:ug]['start_at']
            ugh.end_at    = params[:ug]['end_id']
            ugh.save(false)
          else
            flash[:notice] = '登録ユーザーのグループ割当に失敗しました。'
            location = "/_admin/system/users/new"
            redirect_to location and return
          end
        else
            g_order="level_no ASC,code ASC"
            g_cond = "level_no=1"
            grp = System::Group.find(:first,:conditions=>g_cond,:order=>g_order)
            grp.blank? ? g_id=1:g_id=grp.id

            ugr = System::UsersGroup.new
            ugr.user_id = params[:item]['id']
            ugr.group_id = g_id
            ugr.job_order = 0
            ugr.start_at = Time.now
            ugr.end_at = nil
          if ugr.save
            ugh = System::UsersGroupHistory.new
            ugh.user_id   = @item.id
            ugh.group_id  = params[:ug]['group_id']
            ugh.job_order = params[:ug]['job_order']
            ugh.start_at  = params[:ug]['start_at']
            ugh.end_at    = params[:ug]['end_id']
            ugh.save(false)
          else
            flash[:notice] = '登録ユーザーのグループ割当に失敗しました。'
            location = "/_admin/system/users/new"
            redirect_to location and return
          end
        end
      }
    }
    _create(@item,options)

  end

  def edit
    @action = 'edit'
    @item = System::User.new.find(params[:id])

  end

  def update
    @item = System::User.new.find(params[:id])
    @item.attributes = params[:item]
    _update @item
  end

  def destroy
    @item = System::User.new.find(params[:id])
    @item.state = 'disabled'
    _update @item

  end

  def item_to_xml(item, options = {})
    options[:include] = [:status, :groups]
    xml = ''; xml << item.to_xml(options) do |n|
      #n << item.relation.to_xml(:root => 'relations', :skip_instruct => true, :include => [:group]) if item.relation
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
      filename = "system_users_#{par_item[:nkf]}.csv"
      items = System::User.find(:all)
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

          System::User.truncate_table
          s_to = Gw::Script::Tool.import_csv(file, "system_users")
        end

        redirect_to system_users_path
      end
    else
    end
  end
end
