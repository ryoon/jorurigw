class Doclibrary::Public::AdmsController < ApplicationController

  include Gwboard::Controller::Scaffold
  include Gwboard::Controller::Common
  include Doclibrary::Model::DbnameAlias
  include Doclibrary::Controller::AdmsInclude
  include Gwboard::Controller::Authorize

  def initialize_scaffold
    @title = Doclibrary::Control.find_by_id(params[:title_id])
    return http_error(404) unless @title

    return redirect_to("#{Site.current_node.public_uri}?title_id=#{params[:title_id]}&limit=#{params[:limit]}&state=#{params[:state]}") if params[:reset]

    params[:state] = @title.default_folder.to_s if params[:state].blank?
    begin
      _search_condition
    rescue
      return error_gwbbs_no_database
    end

    initialize_value_set

    if params[:state].to_s == 'GROUP'

      params[:grp] = 1 if params[:grp].blank? or params[:grp].blank? == '0'
      item = doclib_db_alias(Doclibrary::GroupFolder)
      @parent = item.find_by_id(params[:grp])
    end
    if params[:state].to_s == 'CATEGORY'
      params[:cat] = 1 if params[:cat].blank? or params[:cat].blank? == '0'
      item = doclib_db_alias(Doclibrary::Folder)
      @parent = item.find_by_id(params[:cat])
    end
  end

  def _search_condition
    item = doclib_db_alias(Doclibrary::GroupFolder)
    item = item.new
    item.and :title_id, params[:title_id]
    @groups = item.find(:all, :select=>'code,name', :order =>'level_no, sort_no, id').index_by(&:code)
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
    when 'GROUP'
      normal_group_index
    when 'CATEGORY'
      normal_categoey_index
    else
      all_index_admin if @is_admin
      all_index unless @is_admin
    end
  end

  def show
    show_normal
    @is_recognize = check_recognize
    @is_publish = true if @is_admin if @item.state == 'recognized'
    @is_publish = true if @item.editor_id.to_s == Site.user.code.to_s if @item.state == 'recognized'
  end

  def new
    get_role_new

    item = doclib_db_alias(Doclibrary::Doc)
    @item = item.create({
      :state => 'preparation',
      :title_id => params[:title_id],
      :latest_updated_at => Time.now,
      :importance=> 1,
      :one_line_note => 0,
      :section_code => Site.user_group.code,
      :category1_id => params[:cat]
    })

    @item.state = 'draft'

    users_collection

    set_folder_level_code
  end

  def edit
    item = doclib_db_alias(Doclibrary::Doc)
    item = item.new
    item.and :id, params[:id]
    @item = item.find(:first)
    return http_error(404) unless @item
    get_role_edit(@item)
    users_collection
    @recognize = check_recognize
    @publish = true if @is_admin if @item.state == 'recognized'
    @publish = true if @item.editor_id.to_s == Site.user.code.to_s if @item.state == 'recognized'
    set_folder_level_code
  end

  def update
    get_role_update

    users_collection

    set_folder_level_code

    item = doclib_db_alias(Doclibrary::File)
    item = item.new
    item.and :title_id, params[:title_id]
    item.and :parent_id, params[:id]
    @files = item.find(:all)
    attach = 0
    attach = @files.length unless @files.blank?

    item = doclib_db_alias(Doclibrary::Doc)
    @item = item.find(params[:id])
    @item.attributes = params[:item]
    @item.latest_updated_at = Time.now
    @item.attachmentfile = attach
    @item.category_use = @title.category
    @item.creater_admin = true
    @item.editor_admin = false

    update_creater_editor

    destroy_recognizers
    if is_possible_recognize
      save_recognizers
    end

    section_folder_state_update
    _update_plus_location @item, @title.adm_docs_path + gwbbs_params_set
  end

  def destroy
    item = doclib_db_alias(Doclibrary::Doc)
    @item = item.find(params[:id])
    destroy_image_files
    destroy_atacched_files
    destroy_files
    _destroy @item
  end

  def normal_group_index
    item = doclib_db_alias(Doclibrary::GroupFolder)
    folder = item.find_by_id(params[:grp])

    params[:grp] = 1 if folder.blank?
    level_no = 2 if folder.blank?
    parent_id = 1 if folder.blank?

    level_no = folder.level_no + 1 unless folder.blank?
    parent_id = folder.id unless folder.blank?

    item = doclib_db_alias(Doclibrary::GroupFolder)
    item = item.new
    item.and :state, 'public'
    item.and :title_id, params[:title_id]
    item.and :level_no, level_no
    item.and :parent_id, parent_id
    item.page params[:page], params[:limit]
    @folders = item.find(:all, :order=>"level_no, sort_no, code")

    item = doclib_db_alias(Doclibrary::Doc)
    item = item.new
    item.and :state, 'public'
    item.and :title_id, params[:title_id]
    item.and :section_code, params[:gcd]
    item.page params[:page], params[:limit]
    @items = item.find(:all)
    _index @items
  end

  def normal_categoey_index
    item = doclib_db_alias(Doclibrary::Folder)
    folder = item.find_by_id(params[:cat])

    params[:cat] = 1 if folder.blank?
    level_no = 2 if folder.blank?
    parent_id = 1 if folder.blank?

    level_no = folder.level_no + 1 unless folder.blank?
    parent_id = folder.id unless folder.blank?

    item = doclib_db_alias(Doclibrary::Folder)
    item = item.new
    item.and :state, 'public'
    item.and :title_id, params[:title_id]
    item.and :level_no, level_no
    item.and :parent_id, parent_id
    item.page   params[:page], params[:limit]
    @folders = item.find(:all, :order=>"level_no, sort_no, id")

    item = doclib_db_alias(Doclibrary::Doc)
    item = item.new
    item.and :state, 'public'
    item.and :title_id, params[:title_id]
    item.and :category1_id, params[:cat]
    item.page   params[:page], params[:limit]
    @items = item.find(:all)
    _index @items
  end

  def search_index
    item = doclib_db_alias(Doclibrary::Folder)
    item = item.new
    item.and :state, 'public'
    item.and :title_id, params[:title_id]
    item.search params
    item.page   params[:page], params[:limit]
    @folders = item.find(:all, :order=>"level_no, sort_no, id")

    item = doclib_db_alias(Doclibrary::File)
    item = item.new
    item.and 'doclibrary_files.title_id' , params[:title_id]
    item.and "sql","doclibrary_docs.state = 'public'"
    item.search params
    item.page   params[:page], params[:limit]
    @files = item.find(:all,:order=>"filename",:select=>'doclibrary_files.*', :joins => ['inner join doclibrary_docs on doclibrary_files.parent_id=doclibrary_docs.id'])
    _index @files
  end

  def publish_update

    item = doclib_db_alias(Doclibrary::Doc)
    item = item.new
    item.and :state, 'recognized'
    item.and :title_id, params[:title_id]
    item.and :id, params[:id]
    item.and :editor_id, Site.user.code

    item = item.find(:first)
    if item
      item.state = 'public'
      item.published_at = Time.now
      item.save
    end
    redirect_to(@title.adm_docs_path + gwbbs_params_set)
  end

  def recognize_update
    item = doclib_db_alias(Doclibrary::Recognizer)
    item = item.new
    item.and :title_id, params[:title_id]
    item.and :parent_id, params[:id]
    item.and :code, Site.user.code
    item = item.find(:first)
    if item
      item.recognized_at = Time.now
      item.save
    end

    item = doclib_db_alias(Doclibrary::Recognizer)
    item = item.new
    item.and :title_id, params[:title_id]
    item.and :parent_id, params[:id]
    item.and "sql", "recognized_at IS NULL"
    item = item.find(:all)

    if item.length == 0
      item = doclib_db_alias(Doclibrary::Doc)
      item = item.find(params[:id])
      item.state = 'recognized'
      item.recognized_at = Time.now
      item.save
    end
    redirect_to(@title.adm_docs_path + gwbbs_params_set)
  end

  def set_folder_level_code
    group_item = doclib_db_alias(Doclibrary::GroupFolder)
    @group_level = []
    group = group_item.new.find(:all, :conditions => {:level_no => 2}, :order => 'level_no, sort_no, code')
    group.each do |dep|
      @group_level << ['+' + dep.code + dep.name, dep.code]
      group2 = group_item.new.find(:all, :conditions => {:parent_id => dep.id}, :order => 'level_no, sort_no, code')
      group2.each do |sec|
        @group_level << ['+-' + sec.code + sec.name, sec.code]
      end
    end

    category_item = doclib_db_alias(Doclibrary::Folder)
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

  def check_recognize
    item = doclib_db_alias(Doclibrary::Recognizer)
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

  def show_normal
    item = doclib_db_alias(Doclibrary::Doc)
    item = item.new
    item.and :id, params[:id]
    @item = item.find(:first)
    return http_error(404) unless @item

    get_role_show(@item)

    item = doclib_db_alias(Doclibrary::File)
    item = item.new
    item.and :title_id, params[:title_id]
    item.and :parent_id, @item.id
    item.order  'id'
    @files = item.find(:all)

    item = doclib_db_alias(Doclibrary::Recognizer)
    item = item.new
    item.and :title_id, params[:title_id]
    item.and :parent_id, params[:id]
    item.order 'id'
    @recogusers = item.find(:all)
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
          item = doclib_db_alias(Doclibrary::Recognizer)
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
    item = doclib_db_alias(Doclibrary::Recognizer)
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
    item = doclib_db_alias(Doclibrary::Image)

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
    item = doclib_db_alias(Doclibrary::File)
    item.destroy_all(sql_where)

  end

  def destroy_files
    item = doclib_db_alias(Doclibrary::DbFile)
    item.destroy_all(sql_where)
  end

  def recognize_list
    item = doclib_db_alias(Doclibrary::Recognizer)
    item.and :title_id, params[:title_id]
    item.and :parent_id, params[:id]
    item.order 'id'
    @recogusers = item.find(:all)
  end

  def clone
    item = doclib_db_alias(Doclibrary::Doc)
    item = item.new
    item.and :id, params[:id]
    @item = item.find(:first)
    return http_error(404) unless @item
    get_role_edit(@item)
    users_collection
    clone_doc(@item)
  end

  def section_folder_state_update
    group_item = doclib_db_alias(Doclibrary::GroupFolder)
    item = doclib_db_alias(Doclibrary::Doc)
    item = item.new
    item.and :state, 'public'
    item.and :title_id, params[:title_id]
    item.find(:all, :select=>'section_code', :group => 'section_code').each do |code|
      g_item = group_item.new
      g_item.and :title_id, params[:title_id]
      g_item.and :code, code.section_code
      g_item.find(:all).each do |group|
        group_state_rewrite(group,group_item)
      end
    end
  end

  def group_state_rewrite(item,group_item)
    group_item.update(item.id, :state =>'public')
    unless item.parent.blank?
      group_state_rewrite(item.parent, group_item)
    end
  end

end
