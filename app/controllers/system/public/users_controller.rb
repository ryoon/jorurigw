class System::Public::UsersController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
    return redirect_to(request.env['PATH_INFO']) if params[:reset]
  end

  def index
    init_params
    return authentication_error(403) unless @u_role

    item = System::User.new
    item.search params

    item.page   params[:page], nz(params[:limit], 30)

    item.order params[:sort], :code
    @items = item.find(:all)
    _index @items
  end

  def show
    init_params
    return authentication_error(403) unless @u_role
    @item = System::User.new.find(params[:id])

  end

  def new

    init_params
    return authentication_error(403) unless @u_role
    top_cond = "level_no=1"
    @top        = System::Group.find(:first,:conditions=>top_cond)
    @group_id = @top.id
    @item = System::User.new({
      :state      =>  'enabled',
      :ldap       =>  '0'
    })
  end

  def create

    init_params
    return authentication_error(403) unless @u_role
    @item = System::User.new(params[:item])
    @item.id = params[:item]['id']

    location = Gw.chop_with("#{Site.current_node.public_uri}",'/')
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
      },
      :success_redirect_uri=>location
    }
    _create(@item,options)

  end

  def edit
    init_params
    return authentication_error(403) unless @u_role
    @action = 'edit'
    @item = System::User.new.find(params[:id])

  end

  def update
    init_params
    return authentication_error(403) unless @u_role
    @item = System::User.new.find(params[:id])
    @item.attributes = params[:item]
    location = Gw.chop_with("#{Site.current_node.public_uri}",'/')
    options = {
      :success_redirect_uri=>location
      }
    _update(@item,options)
  end

  def destroy
    init_params
    return authentication_error(403) unless @u_role
    @item = System::User.new.find(params[:id])
    flash[:notice] = "削除は実行できません。"
    location = "#{Site.current_node.public_uri}#{@item.id}"
    return redirect_to location

  end

  def init_params

    @role_developer  = System::User.is_dev?
    @role_admin      = System::User.is_admin?
    @role_editor     = System::User.is_editor?
    @u_role = @role_developer || @role_admin || @role_editor

    @limit = nz(params[:limit],30)

    search_condition

    @css = %w(/layout/admin/style.css)

    @piece_header = 'ユーザー管理'

  end

  def search_condition
    params[:limit]        = nz(params[:limit],@limit)

    qsa = ['limit', 's_keyword']
    @qs = qsa.delete_if{|x| nz(params[x],'')==''}.collect{|x| %Q(#{x}=#{params[x]})}.join('&')
  end

end
