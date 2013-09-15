
class Gwfaq::Public::AdmsController < ApplicationController

  include Gwboard::Controller::Scaffold
  include Gwboard::Controller::Common
  include Gwfaq::Model::DbnameAlias
  include Gwfaq::Controller::AdmsInclude
  include Gwboard::Controller::Authorize

  def initialize_scaffold
    @title = Gwfaq::Control.find_by_id(params[:title_id])
    return http_error(404) unless @title

    return redirect_to("#{Site.current_node.public_uri}?title_id=#{params[:title_id]}&limit=#{params[:limit]}&state=#{params[:state]}") if params[:reset]

    begin
      _search_condition
    rescue
      return http_error(404)
    end

    initialize_value_set

  end

  def _search_condition
    item = gwfaq_db_alias(Gwfaq::Category)
    item = item.new
    item.and :level_no, 1
    item.and :title_id, params[:title_id]
    @categories1 = item.find(:all, :order =>'sort_no, id')
  end

  def index
    get_role_index
    return authentication_error(403) unless @is_writable

    case params[:state].to_s
    when 'DRAFT'
      normal_index(true)
    when 'RECOGNIZE'
      recognize_index
    when 'PUBLISH'
      recognized_index_admin if @is_sysadm
      recognized_index unless @is_sysadm
    when 'VOID'
      normal_index(true)
    else
      all_index_admin if @is_sysadm
      all_index unless @is_sysadm
    end
  end

  def show
    get_role_index
    return authentication_error(403) unless @is_readable

    item = gwfaq_db_alias(Gwfaq::Doc)
    item = item.new
    item.and :id, params[:id]
    @item = item.find(:first)
    return http_error(404) unless @item

    get_role_show(@item)
    return authentication_error(403) unless @is_readable

    case params[:state].to_s
    when 'DRAFT'
      recognize_index
    when 'RECOGNIZE'
      recognize_index
    when 'PUBLISH'
      recognized_index_admin if @is_sysadm
      recognized_index unless @is_sysadm
    when 'VOID'
      normal_index
    else
      all_index_admin if @is_sysadm
      all_index unless @is_sysadm
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

    item = gwfaq_db_alias(Gwfaq::File)
    item = item.new
    item.and :title_id, params[:title_id]
    item.and :parent_id, @item.id
    item.order  'id'
    @files = item.find(:all)

    item = gwfaq_db_alias(Gwfaq::Recognizer)
    item = item.new
    item.and :title_id, params[:title_id]
    item.and :parent_id, params[:id]
    item.order 'id'
    @recogusers = item.find(:all)

    @is_recognize = check_recognize
    @is_publish = true if @is_admin if @item.state == 'recognized'
    @is_publish = true if @item.editor_id.to_s == Site.user.code.to_s if @item.state == 'recognized'
  end

  def new
    get_role_new
    return authentication_error(403)  unless @is_writable

    item = gwfaq_db_alias(Gwfaq::Doc)
    @item = item.create({
      :state => 'preparation',
      :title_id => @title.id,
      :latest_updated_at => Time.now,
      :importance=> 1,
      :one_line_note => 0,
      :section_code => Site.user_group.code,
      :title => '',
      :body => ''
    })

    @item.state = 'draft'

    users_collection
  end

  def edit
    get_role_new
    return authentication_error(403) unless @is_writable

    item = gwfaq_db_alias(Gwfaq::Doc)
    item = item.new
    item.and :id, params[:id]
    @item = item.find(:first)
    return http_error(404) unless @item

    get_role_edit(@item)
    return authentication_error(403) unless @is_editable

    users_collection
  end

  def update
    get_role_new
    return authentication_error(403) unless @is_writable

    users_collection

    item = gwfaq_db_alias(Gwfaq::File)
    item = item.new
    item.and :title_id, params[:title_id]
    item.and :parent_id, params[:id]
    @files = item.find(:all)
    attach = 0
    attach = @files.length unless @files.blank?

    item = gwfaq_db_alias(Gwfaq::Doc)
    @item = item.find(params[:id])

    @item.attributes = params[:item]
    @item.latest_updated_at = Time.now
    @item.attachmentfile = attach
    @item.category_use = @title.category
    @item.creater_admin = true
    @item.editor_admin = false

    update_creater_editor

    group = Gwboard::Group.new
    group.and :state , 'enabled'
    group.and :code ,@item.section_code
    group = group.find(:first)
    @item.section_name = group.code + group.name if group

    group = Gwboard::Group.new
    group.and :state , 'enabled'
    group.and :code ,@item.section_code
    group = group.find(:first)
    @item.section_name = group.code + group.name if group

    _update_after_save_recognizers(@item, gwfaq_db_alias(Gwfaq::Recognizer), "#{@title.adm_docs_path}#{gwbbs_params_set}")
  end

  def destroy
    item = gwfaq_db_alias(Gwfaq::Doc)
    @item = item.find(params[:id])

    get_role_edit(@item)
    return authentication_error(403) unless @is_editable

    destroy_image_files
    destroy_atacched_files
    destroy_files
    _destroy @item
  end

  def publish_update
    item = gwfaq_db_alias(Gwfaq::Doc)
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

    item = gwfaq_db_alias(Gwfaq::Recognizer)
    item = item.new
    item.and :title_id, params[:title_id]
    item.and :parent_id, params[:id]
    item.and :code, Site.user.code
    item = item.find(:first)
    if item
      item.recognized_at = Time.now
      item.save
    end

    item = gwfaq_db_alias(Gwfaq::Recognizer)
    item = item.new
    item.and :title_id, params[:title_id]
    item.and :parent_id, params[:id]
    item.and "sql", "recognized_at IS NULL"
    item = item.find(:all)

    if item.length == 0
      item = gwfaq_db_alias(Gwfaq::Doc)
      item = item.find(params[:id])
      item.state = 'recognized'
      item.recognized_at = Time.now
      item.save
    end
    redirect_to(@title.adm_docs_path + gwbbs_params_set)
  end

  def check_recognize
    item = gwfaq_db_alias(Gwfaq::Recognizer)
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

  def destroy_image_files
    item = gwfaq_db_alias(Gwfaq::Image)
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
    item = gwfaq_db_alias(Gwfaq::File)
    item.destroy_all(sql_where)
  end

  def destroy_files
    item = gwfaq_db_alias(Gwfaq::DbFile)
    item.destroy_all(sql_where)
  end

end
