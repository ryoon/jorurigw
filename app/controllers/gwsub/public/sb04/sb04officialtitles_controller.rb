class Gwsub::Public::Sb04::Sb04officialtitlesController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
    return redirect_to(request.env['PATH_INFO']) if params[:reset]
  end

  def index
    init_params
    item = Gwsub::Sb04officialtitle.new #.readable
    item.search params
    item.page   params[:page], params[:limit]
    item.order  params[:id], @sort_keys
    @items = item.find(:all)
    _index @items
  end

  def show
    init_params
    @item = Gwsub::Sb04officialtitle.find(params[:id])
    _show @item
  end

  def new
    init_params
    @l3_current = '03'
    @item = Gwsub::Sb04officialtitle.new
  end
  def create
    init_params
    @l3_current = '03'
    @item = Gwsub::Sb04officialtitle.new(params[:item])
    location = Gw.chop_with("#{Site.current_node.public_uri}",'/').to_s+@param.to_s
    
    if @item.officialtitle_data_save(params, :create)
      flash_notice '更新', true
      redirect_to location
    else
      respond_to do |format|
        format.html { render :action => "new" }
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    init_params
    @item = Gwsub::Sb04officialtitle.find(params[:id])
    @fyed_id = @item.fyear_id
    set_param
  end
  def update
    init_params
    @item = Gwsub::Sb04officialtitle.new.find(params[:id])
    @item.attributes = params[:item]
    location = "#{Site.current_node.public_uri}#{@item.id}#{@param}"

    if @item.officialtitle_data_save(params, :update)
      _update @item, :success_redirect_uri => location
    else
      respond_to do |format|
        format.html { render :action => "edit" }
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
    end    
  end

  def destroy
    init_params
    @item = Gwsub::Sb04officialtitle.find(params[:id])
#    location = "#{Site.current_node.public_uri}"
    location = Gw.chop_with("#{Site.current_node.public_uri}",'/')+@param
    options = {
      :success_redirect_uri=>location}
    _destroy(@item,options)
  end

  def init_params
    # ユーザー権限設定
    @role_developer  = Gwsub::Sb04stafflist.is_dev?(Site.user.id)
    @role_admin      = Gwsub::Sb04stafflist.is_admin?(Site.user.id)
    @u_role = @role_developer || @role_admin

    @menu_header3 = 'sb0404menu'
    @menu_title3  = 'コード管理'
    @menu_header4 = 'sb04officialtitles'
    @menu_title4  = '職名コード'

    # 年度選択　設定
      # 年度変更時は、所属選択をクリア
    if params[:fyed_id]
      if params[:pre_fyear] != params[:fyed_id]
        params[:grped_id] = nil
      end
    else
        params[:grped_id] = nil
    end
    # 年度選択　設定
    # 管理者には、作業中年度も公開

    @fyed_id = nz(params[:fyed_id],0)
    @limits = nz(params[:limit],30)

    search_condition
    sortkeys_setting
    @css = %w(/_common/themes/gw/css/gwsub.css)
    @l1_current = '05'
    @l2_current = '01'
    @l3_current = '01'

    set_param

  end
  def search_condition
    params[:fyed_id] = nz(params[:fyed_id],@fyed_id)
    params[:limit] = nz(params[:limit], @limits)
    @s_keyword = nil
    @s_keyword = params[:s_keyword] unless params[:s_keyword].blank?

    qsa = ['limit', 's_keyword' ,'fyed_id','grped_id' ]
    @qs = qsa.delete_if{|x| nz(params[x],'')==''}.collect{|x| %Q(#{x}=#{params[x]})}.join('&')

  end
  def sortkeys_setting
    @sort_keys = nz(params[:sort_keys], 'fyear_markjp DESC , code_int ASC')
  end

  def csvput
    init_params
    return authentication_error(403) unless @u_role == true
    @l3_current = '04'
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
      filename = "sb04officialtitles_#{par_item[:nkf]}.csv"
        items = Gwsub::Sb04officialtitle.find(:all)
      if items.blank?
      else
        file = Gw::Script::Tool.ar_to_csv(items)
        send_download "#{filename}", NKF::nkf(nkf_options,file)
      end
    else
      location = Gw.chop_with("#{Site.current_node.public_uri}",'/')
      redirect_to location
    end
  end

  def csvup
    init_params
    return authentication_error(403) unless @u_role == true
    @l3_current = '05'
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
          Gwsub::Sb04officialtitle.truncate_table
          s_to = Gw::Script::Tool.import_csv(file, "gwsub_sb04officialtitles")
        end
        location = Gw.chop_with("#{Site.current_node.public_uri}",'/')
        redirect_to location
      end
    else
    end
  end
  def csvadd
    init_params
    return authentication_error(403) unless @u_role == true
    @l3_current = '06'
    return if params[:item].nil?
    par_item = params[:item]
    case par_item[:csv]
    when 'add'
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
          fyear_id = par_item[:fyed_id]
          Gwsub::Sb04officialtitle.destroy_all(:fyear_id=>fyear_id)
          s_to = Gw::Script::Tool.import_csv(file, "gwsub_sb04officialtitles_add")
        end
        location = Gw.chop_with("#{Site.current_node.public_uri}",'/')
        redirect_to location
      end
    else
    end
  end
  def csvadd_check
    init_params
    return authentication_error(403) unless @u_role == true
    @l3_current = '06'
    return if params[:item].nil?
    par_item = params[:item]
    case par_item[:csv]
    when 'add'
      if par_item[:fyed_id].present?
        @fyed_id = nz(par_item[:fyed_id], 0).to_i
        check = Gwsub::Sb04CheckOfficialtitle.csv_check(params)
        if check[:result]
          flash[:notice] = '正常にインポートされました。'
          location = Gw.chop_with("#{Site.current_node.public_uri}",'/') + "/index_csv#{@param}"
          redirect_to location
        else
          flash.now[:notice] = check[:error_msg]
          if check[:error_kind] == 'csv_error'
            file = Gw::Script::Tool.ary_to_csv(check[:csv_data])
            nkf_options = case par_item[:nkf]
            when 'utf8'
              '-w -W'
            when 'sjis'
              '-s -W'
            end
            fyear = Gw::YearFiscalJp.find(:first, :conditions=>"id = #{par_item[:fyed_id]}",:order=>"start_at DESC")
            send_download "#{fyear.markjp}_10職名_エラー箇所追記.csv", NKF::nkf(nkf_options, file)
          end
        end
      else
        flash[:notice] = '年度を指定してください。'
      end
    else
    end
  end

  def index_csv
    init_params
    return authentication_error(403) unless @u_role == true
    item = Gwsub::Sb04CheckOfficialtitle.new #.readable
    item.search params
    item.page   params[:page], params[:limit]
    item.order  params[:id], @sort_keys
    @items = item.find(:all)
    @l3_current = '08'
  end

  def show_csv
    init_params
    return authentication_error(403) unless @u_role == true
    @item = Gwsub::Sb04CheckOfficialtitle.find_by_id(params[:id])
    return http_error(404) if @item.blank?
    @l3_current = '08'
  end
  
  def set_param
    @param = "?"
    @param += "pre_fyear=#{@fyed_id}&"    unless @fyed_id.blank?
    @param += "fyed_id=#{@fyed_id}&"      unless @fyed_id.blank?
    @param += "limit=#{@limits}&"         unless @limits.blank?
    @param += "s_keyword=#{@s_keyword}&"  unless @s_keyword.blank?
    if @param == "?"
      @param=nil
    else
      @param = Gw.chop_with(@param,'&')
    end
  end

end
