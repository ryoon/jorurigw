class Digitallibrary::Public::AdmsController < ApplicationController

  include Gwboard::Controller::Scaffold
  include Gwboard::Controller::Common
  include Digitallibrary::Model::DbnameAlias
  include Digitallibrary::Controller::AdmsInclude
  include Gwboard::Controller::Authorize

  rescue_from ActionController::InvalidAuthenticityToken, :with => :invalidtoken

  def initialize_scaffold
    @title = Digitallibrary::Control.find_by_id(params[:title_id])
    return http_error(404) unless @title
    return redirect_to("#{Site.current_node.public_uri}?title_id=#{params[:title_id]}&limit=#{params[:limit]}&state=#{params[:state]}") if params[:reset]

    begin
      _search_condition
    rescue
      return http_error(404)
    end

    initialize_value_set_new_css_dl

    params[:cat] = '1' if params[:cat].blank?
    item = digitallib_db_alias(Digitallibrary::Folder)
    @parent = item.find_by_id(params[:cat])
  end

  def _search_condition
    params[:cat] = 1 if params[:cat].blank?
    item = digitallib_db_alias(Digitallibrary::Folder)
    @parent = item.find_by_id(params[:cat])
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
    when 'ALL'
      all_index_admin if @is_admin
      all_index unless @is_admin
    else
      select_categoey_index
    end
  end

  def show
    item = digitallib_db_alias(Digitallibrary::Doc)
    item = item.new
    item.and :id, params[:id]
    @item = item.find(:first)
    return http_error(404) unless @item
    get_role_show(@item)
    return http_error(404) unless @is_readable
    get_role_edit(@item)

    item = digitallib_db_alias(Digitallibrary::File)
    item = item.new
    item.and :title_id, params[:title_id]
    item.and :parent_id, @item.id
    item.order  'id'
    @files = item.find(:all)

    item = digitallib_db_alias(Digitallibrary::Recognizer)
    item = item.new
    item.and :title_id, params[:title_id]
    item.and :parent_id, params[:id]
    item.order 'id'
    @recogusers = item.find(:all)

    @recognize = check_recognize
    @publish = true if @is_admin if @item.state == 'recognized'
    @publish = true if @item.editor_id.to_s == Site.user.code.to_s if @item.state == 'recognized'
  end

  def new
    get_role_new
    return http_error(404) unless @is_writable

    item = digitallib_db_alias(Digitallibrary::Doc)
    @item = item.create({
      :state => 'preparation',
      :latest_updated_at => Time.now,
      :parent_id  => @parent.id ,
      :chg_parent_id => @parent.id ,
      :title_id  => params[:title_id] ,
      :doc_type  => 1,
      :level_no => @parent.level_no + 1,
      :seq_no => 999999999 ,
      :order_no => 999999999 ,
      :sort_no => 1999999999 ,
      :section_code => Site.user_group.code,
      :category1_id => params[:cat]
    })

    @item.state = 'draft'

    users_collection

    sort_no_update

    set_tree_list_hash('new')
    set_position_hash(1)
  end

  def edit
    get_role_new
    return http_error(404) unless @is_writable

    item = digitallib_db_alias(Digitallibrary::Doc)
    item = item.new
    item.and :id, params[:id]
    @item = item.find(:first)
    return http_error(404) unless @item
    get_role_edit(@item)
    return http_error(404) unless @is_editable

    @item.section_code = nil if @item.section_code == ''
    @item.section_code = @item.section_code || Site.user_group.code

    users_collection
    @is_recognize = check_recognize
    @is_publish = true if @is_admin if @item.state == 'recognized'
    @is_publish = true if @item.editor_id.to_s == Site.user.code.to_s if @item.state == 'recognized'

    set_tree_list_hash('update')
    set_position_hash(1)
  end

  def update
    users_collection

    item = digitallib_db_alias(Digitallibrary::Doc)
    @item = item.find(params[:id])
    get_role_update(@item)
    return http_error(404) unless @is_editable

    set_tree_list_hash('edit')
    set_position_hash(1)

    @item.attributes = params[:item]
    @item.latest_updated_at = Time.now
    @item.doc_type = 1
    @item.creater_admin = true
    @item.editor_admin = false

    update_creater_editor

    unless @item.parent_id == @item.chg_parent_id
      @item.parent_id = @item.chg_parent_id
      @item.seq_no = 999999999
      @item.save

      item = digitallib_db_alias(Digitallibrary::Folder)
      level_no_rewrite(@item, item)
      sort_no_update
    end

    unless @item.order_no == @item.seq_no
      @item.parent_id == @item.chg_parent_id
      @item.save
      sort_no_update
    end

    destroy_recognizers
    if is_possible_recognize
      save_recognizers
    end

    _update_plus_location @item, @title.adm_docs_path + gwbbs_params_set
  end

  def destroy

    item = digitallib_db_alias(Digitallibrary::Doc)
    @item = item.find(params[:id])

    get_role_update(@item)
    return http_error(404) unless @is_editable

    destroy_image_files
    destroy_atacched_files
    destroy_files
    _destroy @item
  end

  def select_categoey_index
    item = digitallib_db_alias(Digitallibrary::Folder)
    item = item.new
    item.and :doc_type, 0
    item.and :title_id, params[:title_id]
    item.and :parent_id, params[:cat]
    item.page   params[:page], params[:limit]
    @folders = item.find(:all, :order=>"level_no, sort_no, id")

    item = digitallib_db_alias(Digitallibrary::Doc)
    item = item.new
    item.and "sql", "state != 'preparation'"
    item.and :title_id, params[:title_id]
    item.and :doc_type, 1
    item.and :parent_id, params[:cat]
    item.order  'sort_no'
    item.page   params[:page], params[:limit]
    @items = item.find(:all)
  end


  def publish_update

    item = digitallib_db_alias(Digitallibrary::Doc)
    item = item.new
    item.and :state, 'recognized'
    item.and :title_id, params[:title_id]
    item.and :id, params[:id]

    item.and :editor_id, Site.user.code unless @is_admin

    item = item.find(:first)
    if item
      get_role_update(item)
      return redirect_to @title.item_home_path unless @is_editable
    end
    if item
      item.state = 'public'
      item.published_at = Time.now
      item.save
    end
    redirect_to(@title.adm_docs_path + gwbbs_params_set)
  end

  def recognize_update

    item = digitallib_db_alias(Digitallibrary::Recognizer)
    item = item.new
    item.and :title_id, params[:title_id]
    item.and :parent_id, params[:id]
    item.and :code, Site.user.code
    item = item.find(:first)
    if item
      get_role_update(item)
      return redirect_to @title.item_home_path unless @is_editable
    end
    if item
      item.recognized_at = Time.now
      item.save
    end

    item = digitallib_db_alias(Digitallibrary::Recognizer)
    item = item.new
    item.and :title_id, params[:title_id]
    item.and :parent_id, params[:id]
    item.and "sql", "recognized_at IS NULL"
    item = item.find(:all)

    if item.length == 0
      item = digitallib_db_alias(Digitallibrary::Doc)
      item = item.find(params[:id])
      item.state = 'recognized'
      item.recognized_at = Time.now
      item.save
    end
    redirect_to(@title.adm_docs_path + gwbbs_params_set)
  end


  def set_folder_level_code

    group_item = digitallib_db_alias(Digitallibrary::Folder)
    @group_level = []
    group = group_item.new.find(:all, :conditions => {:level_no => 2}, :order => 'level_no, sort_no, code')
    group.each do |dep|
      @group_level << ['+' + dep.code + dep.name, dep.code]
      group2 = group_item.new.find(:all, :conditions => {:parent_id => dep.id}, :order => 'level_no, sort_no, code')
      group2.each do |sec|
        @group_level << ['+-' + sec.code + sec.name, sec.code]
      end
    end

    category_item = digitallib_db_alias(Digitallibrary::Folder)
    @category_level = []
    category = category_item.new.find(:all, :conditions => {:level_no => 2}, :order => 'level_no, sort_no, id')
    category.each do |dep|
      @category_level << ['+' + dep.name, dep.id]
      category2 = category_item.new.find(:all, :conditions => {:parent_id => dep.id}, :order => 'level_no, sort_no, id')
      category2.each do |sec|
        @category_level << ['+-' + sec.name, sec.id]
      end
    end
  end


  def show_normal
  end

  def check_recognize
    item = digitallib_db_alias(Digitallibrary::Recognizer)
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

  def users_collection
    @users_collection = []
    sql = Condition.new
    sql.and "sql", "system_users_groups.group_id = #{Site.user_group.id}"
    join = "INNER JOIN system_users_groups ON system_users.id = system_users_groups.user_id"

    item = System::User.new
    users = item.find(:all, :joins=>join, :order=> 'code', :conditions=>sql.where)
    users.each do |u|
      next if u == Site.user && Site.user.ldap != 0
      next unless @is_admin if u.id == Site.user.id
      @users_collection << u
    end
  end

  def save_recognizers
    @item._recognizers.each do |k, v|
      unless v.to_s == ''
        user = get_user(v.to_s)
        if user
          item = digitallib_db_alias(Digitallibrary::Recognizer)
          item.create(
            :title_id => params[:title_id],
            :parent_id => params[:id],
            :user_id => v.to_s,
            :code => user.code,
            :name => %Q[#{user.name}(#{user.code})]
          )
        end
      end
    end
  end

  def destroy_recognizers
    item = digitallib_db_alias(Digitallibrary::Recognizer)
    item.destroy_all(sql_where)
  end

  def is_possible_recognize
    valid = nil
    if @item.state == 'recognize' && @item._recognizers
      @item._recognizers.each do |k, v|
        valid = true if v.to_s != ''
      end
    end
    return valid
  end

  def get_user(uid)
    ret = nil
    item = System::User.find(uid)
    ret = item if item
    return ret
  end

  def sql_where
    sql = Condition.new
    sql.and "parent_id", @item.id
    sql.and "title_id", @item.title_id
    return sql.where
  end

  def destroy_image_files
    item = digitallib_db_alias(Digitallibrary::Image)

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
    item = digitallib_db_alias(Digitallibrary::File)
    item.destroy_all(sql_where)

  end

  def destroy_files
    item = digitallib_db_alias(Digitallibrary::DbFile)
    item.destroy_all(sql_where)
  end

  def recognize_list
    item = digitallib_db_alias(Digitallibrary::Recognizer)
    item.and :title_id, params[:title_id]
    item.and :parent_id, params[:id]
    item.order 'id'
    @recogusers = item.find(:all)
  end

  def clone
    item = digitallib_db_alias(Digitallibrary::Doc)
    item = item.new
    item.and :id, params[:id]
    @item = item.find(:first)
    return http_error(404) unless @item
    get_role_edit(@item)
    users_collection
    clone_doc(@item)
  end

end
