class Gwsub::Public::Sb04::Sb04stafflistviewMastersController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold

  end

  def init_params

    @is_admin = true # 管理者権限は後に設定する。
    @is_gw_admin = Gw.is_admin_admin? # GW全体の管理者
    @model = Gw::SectionAdminMaster
    @sp_mode = :schedule

    @erb_base = '/gw/public/prop_genre_common'
    @css = %w(/_common/themes/gw/css/gwsub.css)

    @user = Site.user
    @group = Site.user_group
    @gid = Site.user_group.id

    @role_developer  = Gwsub::Sb04stafflist.is_dev?(Site.user.id)
    @role_admin      = Gwsub::Sb04stafflist.is_admin?(Site.user.id)
    @u_role = @role_developer || @role_admin

    @menu_header3 = 'sb04stafflistview_masters'
    @menu_title3  = '職員録'
    @l1_current = '06'
    
    @params_set = Gwsub::Sb04stafflistviewMaster.params_set(params)

    @public_uri = Site.current_node.public_uri

    @fyed_id = Gwsub.set_fyear_select(params[:fyed_id],{:role=>@u_role})
    @section = Gwsub::Sb04section.new.find(:first, :conditions=>["fyear_id = ?", @fyed_id], :select=>"id")
    @section_id = !@section.blank? ? @section.id : 1
  end

  def index
    init_params
    return authentication_error(403) unless @u_role == true
    @l2_current = '01'
    item = @model.new
    item.page  params[:page], params[:limit]

    if params[:s_old_f_id].blank?
      @s_old_f_id = @fyed_id
    else
      @s_old_f_id = params[:s_old_f_id].to_i
    end

    cond = "func_name = 'gwsub_sb04' and state = 'enabled'"

    @s_f_id = nz(params[:s_f_id], "0").to_i  # System::Group.findでは、数値型しか受け入れられないのでto_iとする。
    if @s_f_id != 0
      cond += " and " unless cond.blank?
      cond += "fyear_id_sb04 = #{@s_f_id}"
      if @s_old_f_id != @s_f_id
        params[:s_m_gid] = '0'
        params[:s_d_gid] = '0'
        @s_old_f_id = @s_f_id
      end
    end

    @s_m_gid = nz(params[:s_m_gid], "0").to_i  # System::Group.findでは、数値型しか受け入れられないのでto_iとする。
    if @s_m_gid != 0
      cond += " and " unless cond.blank?
      cond += "management_gid_sb04 = #{@s_m_gid}"
    end

    @s_d_gid = nz(params[:s_d_gid], "0").to_i  # System::Group.findでは、数値型しか受け入れられないのでto_iとする。
    if @s_d_gid != 0
      cond += " and " unless cond.blank?
      cond += "division_gid_sb04 = #{@s_d_gid}"
    end

    # 並び替え用
    @qsa = Gw.params_to_qsa(%w(s_m_gid s_d_gid s_f_id s_old_f_id), params)
    @qs = Gw.qsa_to_qs(@qsa)
    @sort_keys = CGI.unescape(nz(params[:sort_keys], ''))
    order = Gw.join([@sort_keys, "fyear_id_sb04 DESC", "management_gcode", "management_ucode"], ',')

    @items = item.find(:all, :conditions => cond, :order => order)
  end

  def show
    init_params
    return authentication_error(403) unless @u_role == true
    @qsa = Gw.params_to_qsa(%w(s_m_gid s_d_gid sort_keys), params)
    @qs = Gw.qsa_to_qs(@qsa)
    @item = @model.find(params[:id])
  end

  def new
    init_params
    return authentication_error(403) unless @u_role == true
    @l2_current = '02'

    @item = @model.new({})
  end

  def edit
    init_params
    return authentication_error(403) unless @u_role == true
    @item = @model.find(params[:id])
  end

  def create
    init_params
    return authentication_error(403) unless @u_role == true

    _params = put_params(params, :create)
    @item = @model.new(_params)

    if _params[:management_uid_sb04].present? && Gwsub::Sb04stafflistviewMaster.find_uniqueness(_params, :create, nil, @model)  # 重複チェック
      _create @item, :success_redirect_uri => @public_uri + @params_set, :notice => '主管課ユーザーの登録に成功しました。'
    else
      if _params[:management_uid_sb04].blank?
        @item.errors.add("主管課担当者", "を選択してください。")
      else
        @item.errors.add("この主管課担当者", "と、主管課担当範囲の組み合わせは、既に登録されています。")
      end

      respond_to do |format|
        format.html { render :action => "new" }
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
    end

  end

  def update
    init_params
    return authentication_error(403) unless @u_role == true
    id = params[:id]
    @item = @model.find(id)
    _params = put_params(params, :update)
    @item.attributes = _params

    if _params[:management_uid_sb04].present? && Gwsub::Sb04stafflistviewMaster.find_uniqueness(_params, :update, id, @model)  # 重複チェック
      _update @item, :success_redirect_uri => "#{@public_uri}#{id}#{@params_set}", :notice => "主管課ユーザーの更新に成功しました。"
    else
      if _params[:management_uid_sb04].blank?
        @item.errors.add("主管課担当者", "を選択してください。")
      else
        @item.errors.add("この主管課担当者", "と、主管課担当範囲の組み合わせは、既に登録されています。")
      end
      respond_to do |format|
        format.html { render :action => "edit" }
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
    end

  end

  def destroy
    init_params
    return authentication_error(403) unless @u_role == true
    @item = @model.find(params[:id])

    @item.state          = 'deleted'
    @item.deleted_at     = Time.now
    @item.deleted_uid    = @user.id
    @item.deleted_gid    = @gid
    @item.save(false)
    flash[:notice] = "主管課担当割当を削除しました。"
    location = @public_uri + @params_set
    redirect_to location
    return

  end

  def section_fields_year_copy
    init_params
    fyed_id = nz(params[:fyed_id], @fyed_id)
    if @u_role == true
      sections = Gwsub::Sb04section.sb04_group_select(fyed_id, 1)
    else
      sections = Gwsub::Sb04stafflistviewMaster.sb04_dev_group_select(fyed_id.to_i)
    end
    _html_select = ''
    sections.each do |value , key|
      _html_select << "<option value='#{key}'>#{value}</option>"
    end
    respond_to do |format|
      format.csv { render :text => _html_select ,:layout=>false ,:locals=>{:f=>@item} }
    end
  end

  def put_params(_params, action)
    _params = _params[:item]

    if _params[:management_uid_sb04].present?
      staff = Gwsub::Sb04stafflist.find_by_id(_params[:management_uid_sb04])
      user = System::User.find_by_code(staff.staff_no)
      if user.present?
        _params = _params.merge({:management_uid => user.id})
        group = user.groups[0]
        _params = _params.merge({:management_gid => group.id})
        _params = _params.merge({:management_parent_gid => group.parent_id})
      else
        _params = _params.merge({:management_uid => nil, :management_gid => nil, :management_parent_gid => nil})
      end
      _params = _params.merge({:management_ucode => staff.staff_no})
    end
    if !_params[:management_gid_sb04].blank?
      section = Gwsub::Sb04section.find_by_id(_params[:management_gid_sb04])
      _params = _params.merge({ :management_gcode => section.code }) if section.present?
    end
    if !_params[:division_gid_sb04].blank?
      section = Gwsub::Sb04section.find_by_id(_params[:division_gid_sb04])
      _params = _params.merge({ :division_gcode => section.code }) if section.present?
    end
    _params = _params.merge({
      :func_name => 'gwsub_sb04',
      :range_class_id => 2,
    })

    return _params
  end

end
