class Gwbbs::Public::AdmsController < ApplicationController

  include Gwboard::Controller::Scaffold
  include Gwboard::Controller::Common
  include Gwbbs::Model::DbnameAlias
  include Gwbbs::Controller::AdmsInclude
  include Gwboard::Controller::Authorize

  rescue_from ActionController::InvalidAuthenticityToken, :with => :invalidtoken

  def initialize_scaffold
    @title = Gwbbs::Control.find_by_id(params[:title_id])
    return http_error(404) unless @title

    return redirect_to("#{Site.current_node.public_uri}?title_id=#{params[:title_id]}&limit=#{params[:limit]}&state=#{params[:state]}") if params[:reset]

    begin
      _category_condition
    rescue
      return http_error(404)
    end

    initialize_value_set_new_css

    params[:state] = @title.default_mode if params[:state].blank? #並び順の指定が無い時は掲示板に設定された順で表示させる
  end

  def _category_condition
    item = gwbbs_db_alias(Gwbbs::Category)
    item = item.new
    item.and :level_no, 1
    item.and :title_id, params[:title_id]
    @categories1 = item.find(:all,:select=>'id, name', :order =>'sort_no, id')
    @d_categories = item.find(:all,:select=>'id, name', :order =>'sort_no, id').index_by(&:id)
    Gwbbs::Category.remove_connection
  end

  def index
    get_role_index
    return http_error(404) unless @is_writable

    case params[:state].to_s
    when 'DRAFT'
      normal_index(true)
    when 'RECOGNIZE'
      recognize_index
    when 'PUBLISH'
      recognized_index_admin if @is_admin
      recognized_index unless @is_admin
    when 'NEVER'
      normal_index(true)
    when 'VOID'
      normal_index(true)
    else
      all_index_admin if @is_admin
      all_index unless @is_admin
    end
    Gwbbs::Doc.remove_connection
  end

  def show
    get_role_index
    return authentication_error(403) unless @is_readable

    item = gwbbs_db_alias(Gwbbs::Doc)
    item = item.new
    item.and :id, params[:id]
    @item = item.find(:first)
    Gwbbs::Doc.remove_connection
    return http_error(404) unless @item

    get_role_show(@item)  #admin, readable, editable
    return authentication_error(403) unless @is_readable

    case params[:state].to_s
    when 'DRAFT'
      recognize_index
    when 'RECOGNIZE'
      recognize_index
    when 'PUBLISH'
      recognized_index_admin if @is_admin
      recognized_index unless @is_admin
    when 'VOID'
      normal_index
    else
      all_index_admin if @is_admin
      all_index unless @is_admin
    end

    if params[:pp].blank?
      fip = 0
      for item_pp in @items
        fip += 1
        params[:pp] = fip
        break if item_pp.id == params[:id].to_i
      end
    end
    current = params[:pp]
    current = 1 unless current
    current = current.to_i

    @prev_page = current - 1
    @prev_page = nil if @prev_page < 1
    unless @prev_page.blank?
      @previous = @items[@prev_page - 1]
    else
      @previous = nil
    end

    @next_page = current + 1
    @next_page = nil if @items.length < @next_page
    unless @next_page.blank?
      @next = @items[@next_page - 1]
    else
      @next = nil
    end

    item = gwbbs_db_alias(Gwbbs::Comment)
    item = item.new
    item.and :title_id, params[:title_id]
    item.and :parent_id, @item.id
    item.order  'latest_updated_at DESC'
    @comments = item.find(:all)
    Gwbbs::Comment.remove_connection

    item = gwbbs_db_alias(Gwbbs::File)
    item = item.new
    item.and :title_id, params[:title_id]
    item.and :parent_id, @item.id
    item.order  'id'
    @files = item.find(:all)
    Gwbbs::File.remove_connection

    item = gwbbs_db_alias(Gwbbs::Recognizer)
    item = item.new
    item.and :title_id, params[:title_id]
    item.and :parent_id, params[:id]
    item.order 'id'
    @recogusers = item.find(:all)
    Gwbbs::Recognizer.remove_connection

    @is_recognize = check_recognize
    @is_publish = true if @is_admin if @item.state == 'recognized'
    @is_publish = true if @item.editor_id.to_s == Site.user.code.to_s if @item.state == 'recognized'
  end

  def new
    get_role_new
    return authentication_error(403) unless @is_writable

    default_published = is_integer(@title.default_published)
    default_published = 3 unless default_published

    item = gwbbs_db_alias(Gwbbs::Doc)
    @item = item.create({
      :state => 'preparation',
      :title_id => @title.id,
      :latest_updated_at => Time.now,
      :importance=> 1,
      :one_line_note => 0,
      :title => '',
      :body => '',
      :section_code => Site.user_group.code,
      :able_date => Time.now.strftime("%Y-%m-%d"),
      :expiry_date => default_published.months.since.strftime("%Y-%m-%d")
    })

    @item.state = 'draft'
    @item.inpfld_024 = '家族' if @title.form_name == "form003"

    users_collection
    Gwbbs::Doc.remove_connection
  end

  def edit
    get_role_new
    return authentication_error(403) unless @is_writable

    item = gwbbs_db_alias(Gwbbs::Doc)
    item = item.new
    item.and :id, params[:id]
    @item = item.find(:first)
    Gwbbs::Doc.remove_connection
    return http_error(404) unless @item

    get_role_edit(@item)
    return authentication_error(403) unless @is_editable

    @item.section_code = nil if @item.section_code == ''
    @item.section_code = @item.section_code || Site.user_group.code

    users_collection
  end

  def update
    get_role_new
    return authentication_error(403) unless @is_writable

    users_collection

    item = gwbbs_db_alias(Gwbbs::File)
    item = item.new
    item.and :title_id, params[:title_id]
    item.and :parent_id, params[:id]
    @files = item.find(:all)
    attach = 0
    attach = @files.length unless @files.blank?

    item = gwbbs_db_alias(Gwbbs::Doc)
    @item = item.find(params[:id])
    Gwbbs::Doc.remove_connection

    @before_state = @item.state

    @item.attributes = params[:item]

    @item.latest_updated_at = Time.now

    @item.expiry_date = @item.expiry_date.strftime("%Y-%m-%d") + " 23:59:59" unless @item.expiry_date.blank?
    @item.attachmentfile = attach
    @item.category_use = @title.category
    @item.form_name = @title.form_name

    update_creater_editor n

    @item.inpfld_006 = Gwboard.fyear_to_namejp_ymd(@item.inpfld_006d) if @title.form_name == "form006"
    @item.inpfld_006 = Gwboard.fyear_to_namejp_ymd(@item.inpfld_006d) if @title.form_name == "form007"
    @item.inpfld_006w = Gwboard.fyear_to_namejp_ym(@item.inpfld_006d) if @title.form_name == "form006"
    @item.inpfld_006w = Gwboard.fyear_to_namejp_ym(@item.inpfld_006d) if @title.form_name == "form007"

    if @title.form_name == "form003"
      str_title = '＊'
      item_03 = Gwboard::Group.new
      item_03.and :code, @item.inpfld_023
      item_03 = item_03.find(:first)
      if @item.inpfld_024 == "家族"
        str_title = "#{item_03.name} #{@item.inpfld_012} #{@item.inpfld_013} さんの　#{@item.inpfld_014} #{@item.inpfld_015} 様が亡くなられました"
      else
        str_title = "#{item_03.name} #{@item.inpfld_012} #{@item.inpfld_025} さんが亡くなられました"
      end unless item_03.blank?
      @item.title = str_title
    end

    group = Gwboard::Group.new
    group.and :state , 'enabled'
    group.and :code ,@item.section_code
    group = group.find(:first)
    @item.section_name = group.code + group.name if group
    @item._bbs_title_name = @title.title
    @item._notification = @title.notification

    _update_after_save_recognizers(@item, gwbbs_db_alias(Gwbbs::Recognizer), "#{@title.adm_docs_path}#{gwbbs_params_set}")
  end

  def destroy

    item = gwbbs_db_alias(Gwbbs::Doc)
    @item = item.find(params[:id])

    get_role_edit(@item)
    return authentication_error(403) unless @is_editable

    destroy_comments
    destroy_image_files
    destroy_atacched_files
    destroy_files

    @item._notification = @title.notification
    _destroy_plus_location(@item, "#{@title.adm_docs_path}#{gwbbs_params_set}" )
  end

  def publish_update
    #
    item = gwbbs_db_alias(Gwbbs::Doc)
    item = item.new
    item.and :state, 'recognized'
    item.and :title_id, params[:title_id]
    item.and :id, params[:id]

    item = item.find(:first)
    if item
      item.state = 'public'
      item.published_at = Time.now
      item.save
    end
    redirect_to(@title.adm_docs_path + gwbbs_params_set)
  end

  def recognize_update
    item = gwbbs_db_alias(Gwbbs::Recognizer)
    item = item.new
    item.and :title_id, params[:title_id]
    item.and :parent_id, params[:id]
    item.and :code, Site.user.code
    item = item.find(:first)
    if item
      item.recognized_at = Time.now
      item.save
    end

    item = gwbbs_db_alias(Gwbbs::Recognizer)
    item = item.new
    item.and :title_id, params[:title_id]
    item.and :parent_id, params[:id]
    item.and "sql", "recognized_at IS NULL"
    item = item.find(:all)

    if item.length == 0
      item = gwbbs_db_alias(Gwbbs::Doc)
      item = item.find(params[:id])
      item.state = 'recognized'
      item.recognized_at = Time.now
      item.save
    end
    redirect_to(@title.adm_docs_path + gwbbs_params_set)
  end

  def check_recognize
    item = gwbbs_db_alias(Gwbbs::Recognizer)
    item = item.new
    item.and :title_id, params[:title_id]
    item.and :parent_id, params[:id]
    item.and :code, Site.user.code
    item.and 'sql', "recognized_at is null"
    item = item.find(:all)
    ret = nil
    ret = true if item.length != 0
    return ret
  end

  def sql_where
    sql = Condition.new
    sql.and "parent_id", @item.id
    sql.and "title_id", @item.title_id
    return sql.where
  end

  def destroy_comments
    item = gwbbs_db_alias(Gwbbs::Comment)
    item.destroy_all(sql_where)
  end

  def destroy_image_files
    item = gwbbs_db_alias(Gwbbs::Image)

    image = item.new
    image.and :parent_id, @item.id
    image.and :title_id, @item.title_id
    image = image.find(:first)
    begin
      image.image_delete_all(@img_path) if image
    rescue
    end
    item.destroy_all(sql_where)
  end

  def destroy_atacched_files
    item = gwbbs_db_alias(Gwbbs::File)
    item.destroy_all(sql_where)
  end

  def destroy_files
    item = gwbbs_db_alias(Gwbbs::DbFile)
    item.destroy_all(sql_where)
  end

  def clone
    item = gwbbs_db_alias(Gwbbs::Doc)
    item = item.new
    item.and :id, params[:id]
    @item = item.find(:first)
    return http_error(404) unless @item
    get_role_edit(@item)
    users_collection
    clone_doc(@item)
  end

private
  def invalidtoken
    return http_error(404)
  end
end
