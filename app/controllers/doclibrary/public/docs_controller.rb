class Doclibrary::Public::DocsController < ApplicationController

  include Gwboard::Controller::Scaffold
  include Gwboard::Controller::Common
  include Doclibrary::Model::DbnameAlias
  include Gwboard::Controller::Authorize

  def initialize_scaffold
    @title = Doclibrary::Control.find_by_id(params[:title_id])
    return http_error(404) unless @title

    return redirect_to("#{Site.current_node.public_uri}?title_id=#{params[:title_id]}&limit=#{params[:limit]}&state=#{params[:state]}") if params[:reset]

    if params[:state].blank?
      params[:state] = 'CATEGORY' unless params[:cat].blank?
      params[:state] = 'GROUP' unless params[:gcd].blank?
      if params[:cat].blank?
        params[:state] = @title.default_folder.to_s if params[:state].blank?
      end if params[:gcd].blank?
    end

    begin
      _search_condition
    rescue
      return http_error(404)
    end
    initialize_value_set
  end

  def _search_condition
    group_hash
    category_hash
    Doclibrary::Doc.remove_connection

    if params[:state].to_s == 'CATEGORY'
      params[:cat] = 1 if params[:cat].blank?
      item = doclib_db_alias(Doclibrary::Folder)
      @parent = item.find_by_id(params[:cat])
    end

    if params[:state].to_s == 'DATE' || params[:state].to_s == 'DRAFT'
      item = doclib_db_alias(Doclibrary::Folder)
      @parent = item.find_by_id(params[:cat])
    end unless params[:cat].blank?
    Doclibrary::Folder.remove_connection
    Doclibrary::GroupFolder.remove_connection
  end

  def group_hash
    item = doclib_db_alias(Doclibrary::Doc)
    item = item.new
    item.and :title_id , @title.id
    item.and :state, 'public' unless params[:state].to_s == 'DRAFT'
    item.and :state, 'draft' if params[:state].to_s == 'DRAFT'

    items = item.find(:all, :select=>'section_code',:group => 'section_code')
    sql = Condition.new
    if items.blank?
      sql.and :id, 0
    else
      for citem in items
        sql.or :code, citem.section_code
      end
    end
    @select_groups = Gwboard::Group.new.find(:all,:conditions=>sql.where, :select=>'code, name' , :order=>'sort_no, code')
    @groups = Gwboard::Group.level3_all_hash
  end

  def category_hash
    item = doclib_db_alias(Doclibrary::Folder)
    item = item.new
    item.and :state, 'public'
    item.and :title_id , params[:title_id]
    @categories = item.find(:all, :select => 'id, name').index_by(&:id)

    item = doclib_db_alias(Doclibrary::Folder)
    parent = item.find(:all, :conditions=>["parent_id IS NULL"], :order=>"level_no, sort_no, id")
    @select_categories = []
    make_group_trees(parent)
  end

  def make_group_trees(items)
   items.each do |item|
     str = "+"
     str += "-" * (item.level_no - 1)
     @select_categories << [item.id , str + item.name]  if 1 < item.level_no if item.state == 'public'
     make_group_trees(item.children) if item.children.count > 0
   end if items.count > 0
  end

  def index
    get_role_index
    return authentication_error(403) unless @is_readable
    if @title.form_name == 'form002'
      index_form002
    else
      index_form001
    end

    Doclibrary::Doc.remove_connection
    Doclibrary::File.remove_connection
    Doclibrary::Folder.remove_connection
    Doclibrary::FolderAcl.remove_connection
    Doclibrary::GroupFolder.remove_connection
  end

  def index_form002
    unless params[:kwd].blank?
      search_index_docs
    else
      if params[:state].to_s== 'DRAFT'
       normal_draft_index_form002
      else
       normal_categoey_index
      end
    end
  end

  def index_form001
    unless params[:kwd].blank?
      case params[:state].to_s
      when 'DATE'
        normal_date_index
      when 'CATEGORY'
        search_category_index
      when 'DRAFT'
        category_folder_items('draft')
        normal_draft_index
      when 'RECOGNIZE'
        recognize_index
      when 'PUBLISH'
        recognized_index
      else
        search_group_index
      end

      search_files_index
    else
      case params[:state].to_s
      when 'DATE'
        normal_date_index
      when 'CATEGORY'
        normal_categoey_index
      when 'DRAFT'
        category_folder_items('draft')
        normal_draft_index
      when 'RECOGNIZE'
        recognize_index
      when 'PUBLISH'
        recognized_index
      else
        normal_group_index
      end
    end
  end

  def new
    get_role_new
    return authentication_error(403) unless @is_writable

    item = doclib_db_alias(Doclibrary::Doc)
    str_section_code = Site.user_group.code
    str_section_code = params[:gcd].to_s unless params[:gcd].to_s == '1' unless params[:gcd].blank?
    @item = item.create({
      :state => 'preparation',
      :title_id => @title.id ,
      :latest_updated_at => Time.now,
      :importance=> 1,
      :one_line_note => 0,
      :section_code => str_section_code ,
      :category4_id => 0,
      :category1_id => params[:cat]
    })

    @item.state = 'draft'

    set_folder_level_code
    form002_categories if @title.form_name == 'form002'
    users_collection unless @title.recognize == 0
  end

  def is_i_have_readable(folder_id)
    return true if @is_recognize_readable
    return false if folder_id.blank?
    p_grp_code = ''
    p_grp_code = Site.user_group.parent.code unless Site.user_group.parent.blank?
    grp_code = ''
    grp_code = Site.user_group.code unless Site.user_group.blank?

    sql = Condition.new
    sql.or {|d|
      d.and :title_id , @title.id
      d.and :folder_id, folder_id
      d.and :acl_flag , 0
    }
    if @is_admin

      sql.or {|d|
        d.and :title_id , @title.id
        d.and :folder_id, folder_id
        d.and :acl_flag , 9
      }
    else

      sql.or {|d|
        d.and :title_id , @title.id
        d.and :folder_id, folder_id
        d.and :acl_flag , 1
        d.and :acl_section_code , p_grp_code
      }

      sql.or {|d|
        d.and :title_id , @title.id
        d.and :folder_id, folder_id
        d.and :acl_flag , 1
        d.and :acl_section_code , grp_code
      }

      sql.or {|d|
        d.and :title_id , @title.id
        d.and :folder_id, folder_id
        d.and :acl_flag , 2
        d.and :acl_user_code , Site.user.code
      }
    end
    item = doclib_db_alias(Doclibrary::FolderAcl)
    item = item.new
    items = item.find(:all, :conditions => sql.where)
    Doclibrary::FolderAcl.remove_connection
    return false if items.blank?
    return false if items.count == 0
    return true unless items.count == 0
  end

  def show
    get_role_index
    return authentication_error(403) unless @is_readable

    admin_flags(params[:title_id])

    @is_recognize = check_recognize
    @is_recognize_readable = check_recognize_readable

    item = doclib_db_alias(Doclibrary::Doc)
    item = item.new
    item.and :id, params[:id]
    @item = item.find(:first)
    Doclibrary::Doc.remove_connection
    return http_error(404) unless @item
    get_role_show(@item)

    return authentication_error(403) unless is_i_have_readable(@item.category1_id)

    @is_recognize = false unless @item.state == 'recognize'

    get_role_show(@item)
    @is_readable = true if @is_recognize_readable
    return authentication_error(403) unless @is_readable

    if @title.form_name == 'form002'
      item = doclib_db_alias(Doclibrary::Folder)
      @parent = item.find_by_id(@item.category1_id)
      Doclibrary::Folder.remove_connection
    end

    item = doclib_db_alias(Doclibrary::File)
    item = item.new
    item.and :title_id, @title.id
    item.and :parent_id, @item.id unless @title.form_name == 'form002'
    item.and :parent_id, @item.category2_id if @title.form_name == 'form002'
    item.order  'id'
    @files = item.find(:all)
    Doclibrary::File.remove_connection

    get_recogusers
    @is_publish = true if @is_admin if @item.state == 'recognized'
    @is_publish = true if @item.section_code.to_s == Site.user_group.code.to_s if @item.state == 'recognized'
  end

  def edit
    get_role_new
    return authentication_error(403) unless @is_writable

    item = doclib_db_alias(Doclibrary::Doc)
    item = item.new
    item.and :id, params[:id]
    @item = item.find(:first)
    Doclibrary::Doc.remove_connection
    return http_error(404) unless @item

    return authentication_error(403) unless is_i_have_readable(@item.category1_id)

    get_role_edit(@item)
    return authentication_error(403) unless @is_editable

    set_folder_level_code
    form002_categories if @title.form_name == 'form002'
    unless @title.recognize == 0
      get_recogusers
      set_recogusers
      users_collection('edit')
    end
  end

  def update
    get_role_new
    return authentication_error(403) unless @is_writable

    item = doclib_db_alias(Doclibrary::Doc)
    @item = item.find(params[:id])
    return http_error(404) unless @item

    set_folder_level_code
    form002_categories if @title.form_name == 'form002'
    unless @title.recognize.to_s == '0'
      users_collection
    end

    item = doclib_db_alias(Doclibrary::File)
    item = item.new
    item.and :title_id, @title.id
    item.and :parent_id, params[:id]
    item.order 'id'
    @files = item.find(:all)
    Doclibrary::File.remove_connection
    attach = 0
    attach = @files.length unless @files.blank?

    item = doclib_db_alias(Doclibrary::Doc)
    @item = item.find(params[:id])
    @item.attributes = params[:item]
    @item.latest_updated_at = Time.now
    @item.attachmentfile = attach
    @item.category_use = 1
    @item.form_name = @title.form_name

    group = Gwboard::Group.new
    group.and :state , 'enabled'
    group.and :code ,@item.section_code
    group = group.find(:first)
    @item.section_name = group.code + group.name if group
    @item._note_section = group.name if group

    update_creater_editor

    if @title.form_name == 'form002'
      set_form002_params
      @item.note = return_form002_attached_url
    end
    section_folder_state_update

    if @title.notification == 1
      note = doclib_db_alias(Doclibrary::FolderAcl)
      note = note.new
      note.and :title_id,  @title.id
      note.and :folder_id, @item.category1_id
      note.and :acl_flag, '<', 9
      notes = note.find(:all)
      @item._acl_records = notes
      @item._notification = @title.notification
      @item._bbs_title_name = @title.title
    end

    if @title.recognize == 0
      _update_plus_location @item, @item.docs_path(params)
    else
      _update_after_save_recognizers(@item, doclib_db_alias(Doclibrary::Recognizer), @item.docs_path(params))
    end
  end

  def destroy
    item = doclib_db_alias(Doclibrary::Doc)
    @item = item.find(params[:id])

    get_role_edit(@item)
    return authentication_error(403) unless @is_editable

    destroy_image_files
    destroy_atacched_files
    destroy_files

    @item._notification = @title.notification
    _destroy_plus_location @item,@item.item_path(params)
  end

  def edit_file_memo
    get_role_index
    return authentication_error(403) unless @is_readable

    item = doclib_db_alias(Doclibrary::Doc)
    item = item.new
    item.and :id, params[:parent_id]
    Doclibrary::Doc
    @item = item.find(:first)
    return http_error(404) unless @item
    get_role_show(@item)

    item = doclib_db_alias(Doclibrary::File)
    item = item.new
    item.and :title_id, @title.id
    item.and :parent_id, @item.id unless @title.form_name == 'form002'
    item.and :parent_id, @item.category2_id if @title.form_name == 'form002'
    item.order  'id'
    @files = item.find(:all)

    item = doclib_db_alias(Doclibrary::File)
    item = item.new
    @file = item.find(params[:id])
  end

  def search_files_index
    parent_grp = Site.user.groups[0].parent unless Site.user.groups[0].blank?
    p_grp_code = ''
    p_grp_code = parent_grp.code unless parent_grp.blank?
    grp_code = ''
    grp_code = Site.user.groups[0].code unless Site.user.groups.blank?
    item = doclib_db_alias(Doclibrary::ViewAclFile)
    item = item.new
    search_cond = item.get_keywords_condition(params[:kwd], :filename) unless params[:kwd].blank?

    sql = Condition.new
    sql.or {|d|
      d.and :title_id , @title.id
      d.and :docs_state, 'public'
      d.and :section_code , params[:gcd] unless params[:gcd].to_s == '1' unless params[:gcd].blank?
      d.and :category1_id , params[:cat] unless params[:cat].to_s == '1' unless params[:cat].blank?
      d.and :acl_flag , 0
      d.and search_cond unless search_cond.blank?
    }
    if @is_admin

      sql.or {|d|
        d.and :title_id , @title.id
        d.and :docs_state, 'public'
        d.and :section_code , params[:gcd] unless params[:gcd].to_s == '1' unless params[:gcd].blank?
        d.and :category1_id , params[:cat] unless params[:cat].to_s == '1' unless params[:cat].blank?
        d.and :acl_flag , 9
        d.and search_cond unless search_cond.blank?
      }
    else

      sql.or {|d|
        d.and :title_id , @title.id
        d.and :docs_state, 'public'
        d.and :section_code , params[:gcd] unless params[:gcd].to_s == '1' unless params[:gcd].blank?
        d.and :category1_id , params[:cat] unless params[:cat].to_s == '1' unless params[:cat].blank?
        d.and :acl_flag , 1
        d.and :acl_section_code , p_grp_code
        d.and search_cond unless search_cond.blank?
      }

      sql.or {|d|
        d.and :title_id , @title.id
        d.and :docs_state, 'public'
        d.and :section_code , params[:gcd] unless params[:gcd].to_s == '1' unless params[:gcd].blank?
        d.and :category1_id , params[:cat] unless params[:cat].to_s == '1' unless params[:cat].blank?
        d.and :acl_flag , 1
        d.and :acl_section_code , grp_code
        d.and search_cond unless search_cond.blank?
      }

      sql.or {|d|
        d.and :title_id , @title.id
        d.and :docs_state, 'public'
        d.and :section_code , params[:gcd] unless params[:gcd].to_s == '1' unless params[:gcd].blank?
        d.and :category1_id , params[:cat] unless params[:cat].to_s == '1' unless params[:cat].blank?
        d.and :acl_flag , 2
        d.and :acl_user_code , Site.user.code
        d.and search_cond unless search_cond.blank?
      }
    end
    item.page   params[:page], params[:limit]
    @files = item.find(:all,:conditions=>sql.where, :order=>"filename")
  end

  def search_group_index

    parent_grp = Site.user.groups[0].parent unless Site.user.groups[0].blank?
    p_grp_code = ''
    p_grp_code = parent_grp.code unless parent_grp.blank?
    grp_code = ''
    grp_code = Site.user.groups[0].code unless Site.user.groups.blank?
    str_order = "doclibrary_view_acl_docs.sort_no, category1_id, title, updated_at DESC, created_at DESC"
    item = doclib_db_alias(Doclibrary::Doc)
    item = item.new
    search_cond = item.get_keywords_condition(params[:kwd], :title, :body) unless params[:kwd].blank?
    sql_section_code_narrow_down

    sql = Condition.new
    sql.or {|d|
      d.and 'doclibrary_docs.title_id' , @title.id
      d.and 'doclibrary_docs.state', 'public'
      d.and 'doclibrary_docs.category1_id' , params[:cat] unless params[:cat].to_s == '1' unless params[:cat].blank?
      d.and 'sql', @str_section_sql unless @str_section_sql.blank?
      d.and 'doclibrary_view_acl_docs.acl_flag' , 0
      d.and search_cond unless search_cond.blank?
    }
    if @is_admin

      sql.or {|d|
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'doclibrary_docs.state', 'public'
        d.and 'doclibrary_docs.category1_id' , params[:cat] unless params[:cat].to_s == '1' unless params[:cat].blank?
        d.and 'sql', @str_section_sql unless @str_section_sql.blank?
        d.and 'doclibrary_view_acl_docs.acl_flag' , 9
        d.and search_cond unless search_cond.blank?
      }
    else

      sql.or {|d|
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'doclibrary_docs.state', 'public'
        d.and 'doclibrary_docs.category1_id' , params[:cat] unless params[:cat].to_s == '1' unless params[:cat].blank?
        d.and 'sql', @str_section_sql unless @str_section_sql.blank?
        d.and 'doclibrary_view_acl_docs.acl_flag' , 1
        d.and 'doclibrary_view_acl_docs.acl_section_code' , p_grp_code
        d.and search_cond unless search_cond.blank?
      }

      sql.or {|d|
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'doclibrary_docs.state', 'public'
        d.and 'doclibrary_docs.category1_id' , params[:cat] unless params[:cat].to_s == '1' unless params[:cat].blank?
        d.and 'sql', @str_section_sql unless @str_section_sql.blank?
        d.and 'doclibrary_view_acl_docs.acl_flag' , 1
        d.and 'doclibrary_view_acl_docs.acl_section_code' , grp_code
        d.and search_cond unless search_cond.blank?
      }

      sql.or {|d|
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'doclibrary_docs.state', 'public'
        d.and 'doclibrary_docs.category1_id' , params[:cat] unless params[:cat].to_s == '1' unless params[:cat].blank?
        d.and 'sql', @str_section_sql unless @str_section_sql.blank?
        d.and 'doclibrary_view_acl_docs.acl_flag' , 2
        d.and 'doclibrary_view_acl_docs.acl_user_code' , Site.user.code
        d.and search_cond unless search_cond.blank?
      }
    end
    item.page params[:page], params[:limit]
    @items = item.find(:all,:conditions=>sql.where, :order=>str_order, :select=>'doclibrary_docs.*' ,:joins => ['inner join doclibrary_view_acl_docs on doclibrary_docs.id = doclibrary_view_acl_docs.id'])
  end

  def sql_section_code_narrow_down
    @str_section_sql = ""
    unless params[:gcd].blank?
      item = doclib_db_alias(Doclibrary::GroupFolder)
      item = item.new
      item.and :title_id, @title.id
      item.and :state, 'public'
      item.and :code, params[:gcd].to_s
      items = item.find(:all)
      section_narrow_sql(items) if items
    end
    @str_section_sql = "(#{@str_section_sql})" unless @str_section_sql.blank?
  end
  def section_narrow_sql(items)
    items.each do |item|
      @str_section_sql += " OR " unless @str_section_sql == ""
      @str_section_sql += "doclibrary_docs.section_code='#{item.code}'"
      section_narrow_sql(item.children) if item.children.size > 0
    end
  end

  def search_category_index
    parent_grp = Site.user.groups[0].parent unless Site.user.groups[0].blank?
    p_grp_code = ''
    p_grp_code = parent_grp.code unless parent_grp.blank?
    grp_code = ''
    grp_code = Site.user.groups[0].code unless Site.user.groups.blank?
    str_order = "doclibrary_view_acl_docs.sort_no, section_code, doclibrary_docs.title, doclibrary_docs.updated_at DESC, doclibrary_docs.created_at DESC"
    item = doclib_db_alias(Doclibrary::Doc)
    item = item.new
    search_cond = item.get_keywords_condition(params[:kwd], :title, :body) unless params[:kwd].blank?
    sql_category_code_narrow_down

    sql = Condition.new
    sql.or {|d|
      d.and 'doclibrary_docs.state', 'public'
      d.and 'doclibrary_docs.title_id' , @title.id
      d.and 'sql', @str_category_sql unless @str_category_sql.blank?
      d.and 'doclibrary_docs.section_code' , params[:gcd] unless params[:gcd].to_s == '1' unless params[:gcd].blank?
      d.and 'doclibrary_view_acl_docs.acl_flag' , 0
      d.and search_cond unless search_cond.blank?
    }
    if @is_admin

      sql.or {|d|
        d.and 'doclibrary_docs.state', 'public'
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'sql', @str_category_sql unless @str_category_sql.blank?
        d.and 'doclibrary_docs.section_code' , params[:gcd] unless params[:gcd].to_s == '1' unless params[:gcd].blank?
        d.and 'doclibrary_view_acl_docs.acl_flag' , 9
        d.and search_cond unless search_cond.blank?
      }
    else

      sql.or {|d|
        d.and 'doclibrary_docs.state', 'public'
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'sql', @str_category_sql unless @str_category_sql.blank?
        d.and 'doclibrary_docs.section_code' , params[:gcd] unless params[:gcd].to_s == '1' unless params[:gcd].blank?
        d.and 'doclibrary_view_acl_docs.acl_flag' , 1
        d.and 'doclibrary_view_acl_docs.acl_section_code' , p_grp_code
        d.and search_cond unless search_cond.blank?
      }

      sql.or {|d|
        d.and 'doclibrary_docs.state', 'public'
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'sql', @str_category_sql unless @str_category_sql.blank?
        d.and 'doclibrary_docs.section_code' , params[:gcd] unless params[:gcd].to_s == '1' unless params[:gcd].blank?
        d.and 'doclibrary_view_acl_docs.acl_flag' , 1
        d.and 'doclibrary_view_acl_docs.acl_section_code' , grp_code
        d.and search_cond unless search_cond.blank?
      }

      sql.or {|d|
        d.and 'doclibrary_docs.state', 'public'
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'sql', @str_category_sql unless @str_category_sql.blank?
        d.and 'doclibrary_docs.section_code' , params[:gcd] unless params[:gcd].to_s == '1' unless params[:gcd].blank?
        d.and 'doclibrary_view_acl_docs.acl_flag' , 2
        d.and 'doclibrary_view_acl_docs.acl_user_code' , Site.user.code
        d.and search_cond unless search_cond.blank?
      }
    end
    item.page params[:page], params[:limit]
    @items = item.find(:all,:conditions=>sql.where, :order=>str_order, :select=>'doclibrary_docs.*' ,:joins => ['inner join doclibrary_view_acl_docs on doclibrary_docs.id = doclibrary_view_acl_docs.id'])
  end

  def sql_category_code_narrow_down
    @str_category_sql = ""
    unless params[:cat].blank?
      item = doclib_db_alias(Doclibrary::Folder)
      item = item.new
      item.and :title_id, @title.id
      item.and :state, 'public'
      item.and :id, params[:cat]
      items = item.find(:all,:select=>'id')
      category_narrow_sql(items) if items
    end
    @str_category_sql = "(#{@str_category_sql})" unless @str_category_sql.blank?
  end

  def category_narrow_sql(items)
    items.each do |item|
      @str_category_sql += " OR " unless @str_category_sql == ""
      @str_category_sql += "doclibrary_docs.category1_id=#{item.id}"
      category_narrow_sql(item.children) if item.children.size > 0
    end
  end

  def search_index_docs

    item = doclib_db_alias(Doclibrary::Doc)
    item = item.new
    item.and :state, 'public'
    item.and :title_id, params[:title_id]
    item.search params
    item.page   params[:page], params[:limit]
    @items = item.find(:all, :order => "inpfld_001 , inpfld_002 DESC, inpfld_003, inpfld_004, inpfld_005, inpfld_006")
  end

  def normal_group_index
    parent_grp = Site.user.groups[0].parent unless Site.user.groups[0].blank?
    p_grp_code = ''
    p_grp_code = parent_grp.code unless parent_grp.blank?
    grp_code = ''
    grp_code = Site.user.groups[0].code unless Site.user.groups.blank?
    str_order = "doclibrary_docs.section_code, doclibrary_view_acl_docs.sort_no, doclibrary_docs.category1_id, doclibrary_docs.updated_at DESC, doclibrary_docs.created_at DESC"
    item = doclib_db_alias(Doclibrary::Doc)
    item = item.new
    search_cond = item.get_keywords_condition(params[:kwd], :body) unless params[:kwd].blank?
    sql = Condition.new

    sql.or {|d|
      d.and 'doclibrary_docs.title_id' , @title.id
      d.and 'doclibrary_docs.state', 'public'
      d.and 'doclibrary_docs.section_code' , params[:gcd] unless params[:gcd].blank?
      d.and 'doclibrary_docs.category1_id' , params[:cat] unless params[:cat].blank?
      d.and 'doclibrary_view_acl_docs.acl_flag' , 0
      d.and search_cond unless search_cond.blank?
    }
    if @is_admin

      sql.or {|d|
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'doclibrary_docs.state', 'public'
        d.and 'doclibrary_docs.section_code' , params[:gcd] unless params[:gcd].blank?
        d.and 'doclibrary_docs.category1_id' , params[:cat] unless params[:cat].blank?
        d.and 'doclibrary_view_acl_docs.acl_flag' , 9
        d.and search_cond unless search_cond.blank?
      }
    else

      sql.or {|d|
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'doclibrary_docs.state', 'public'
        d.and 'doclibrary_docs.section_code' , params[:gcd] unless params[:gcd].blank?
        d.and 'doclibrary_docs.category1_id' , params[:cat] unless params[:cat].blank?
        d.and 'doclibrary_view_acl_docs.acl_flag' , 1
        d.and 'doclibrary_view_acl_docs.acl_section_code' , p_grp_code
        d.and search_cond unless search_cond.blank?
      }

      sql.or {|d|
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'doclibrary_docs.state', 'public'
        d.and 'doclibrary_docs.section_code' , params[:gcd] unless params[:gcd].blank?
        d.and 'doclibrary_docs.category1_id' , params[:cat] unless params[:cat].blank?
        d.and 'doclibrary_view_acl_docs.acl_flag' , 1
        d.and 'doclibrary_view_acl_docs.acl_section_code' , grp_code
        d.and search_cond unless search_cond.blank?
      }

      sql.or {|d|
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'doclibrary_docs.state', 'public'
        d.and 'doclibrary_docs.section_code' , params[:gcd] unless params[:gcd].blank?
        d.and 'doclibrary_docs.category1_id' , params[:cat] unless params[:cat].blank?
        d.and 'doclibrary_view_acl_docs.acl_flag' , 2
        d.and 'doclibrary_view_acl_docs.acl_user_code' , Site.user.code
        d.and search_cond unless search_cond.blank?
      }
    end
    item.page params[:page], params[:limit]
    @items = item.find(:all, :conditions=>sql.where, :order=>str_order, :select=>'doclibrary_docs.*' ,:joins => ['inner join doclibrary_view_acl_docs on doclibrary_docs.id = doclibrary_view_acl_docs.id'])
  end


  def normal_categoey_index
    category_folder_items

    unless @title.form_name == 'form002'
      norm_cat_items
    else
      norm_cat_index_form002
    end
  end

  def category_folder_items(state=nil)
    item = doclib_db_alias(Doclibrary::Folder)
    folder = item.find_by_id(params[:cat])

    params[:cat] = 1 if folder.blank?
    level_no = 2 if folder.blank?
    parent_id = 1 if folder.blank?

    level_no = folder.level_no + 1 unless folder.blank?
    parent_id = folder.id unless folder.blank?

    parent_grp = Site.user.groups[0].parent unless Site.user.groups[0].blank?
    p_grp_code = ''
    p_grp_code = parent_grp.code unless parent_grp.blank?
    grp_code = ''
    grp_code = Site.user.groups[0].code unless Site.user.groups.blank?
    sql = Condition.new

    str_state = 'public'
    str_state = 'closed' if state == 'draft'
    sql.or {|d|
      d.and :state, str_state
      d.and :title_id, @title.id
      d.and :level_no, level_no unless state == 'draft'
      d.and :parent_id, parent_id unless state == 'draft'
      d.and :acl_flag , 0
    }
    if @is_admin

      sql.or {|d|
        d.and :state, str_state
        d.and :title_id, @title.id
        d.and :level_no, level_no unless state == 'draft'
        d.and :parent_id, parent_id  unless state == 'draft'
        d.and :acl_flag , 9
      }
    else

      sql.or {|d|
        d.and :state, str_state
        d.and :title_id, @title.id
        d.and :level_no, level_no unless state == 'draft'
        d.and :parent_id, parent_id unless state == 'draft'
        d.and :acl_flag , 1
        d.and :acl_section_code , p_grp_code
      }

      sql.or {|d|
        d.and :state, str_state
        d.and :title_id, @title.id
        d.and :level_no, level_no unless state == 'draft'
        d.and :parent_id, parent_id unless state == 'draft'
        d.and :acl_flag , 1
        d.and :acl_section_code , grp_code
      }

      sql.or {|d|
        d.and :state, str_state
        d.and :title_id, @title.id
        d.and :level_no, level_no unless state == 'draft'
        d.and :parent_id, parent_id unless state == 'draft'
        d.and :acl_flag , 2
        d.and :acl_user_code , Site.user.code
      }
    end
    item = doclib_db_alias(Doclibrary::ViewAclFolder)
    item = item.new
    item.page   params[:page], params[:limit]
    @folders = item.find(:all, :conditions=>sql.where, :order=>"level_no, sort_no, id")
  end

  def norm_cat_items
    parent_grp = Site.user.groups[0].parent unless Site.user.groups[0].blank?
    p_grp_code = ''
    p_grp_code = parent_grp.code unless parent_grp.blank?
    grp_code = ''
    grp_code = Site.user.groups[0].code unless Site.user.groups.blank?
    str_order = "doclibrary_view_acl_docs.sort_no, section_code, doclibrary_docs.title, doclibrary_docs.updated_at DESC, doclibrary_docs.created_at DESC"
    sql = Condition.new

    sql.or {|d|
      d.and 'doclibrary_docs.state', 'public'
      d.and 'doclibrary_docs.title_id' , @title.id
      d.and 'doclibrary_docs.category1_id' , params[:cat]
      d.and 'doclibrary_docs.section_code' , params[:gcd] unless params[:gcd].blank?
      d.and 'doclibrary_view_acl_docs.acl_flag' , 0
    }
    if @is_admin

      sql.or {|d|
        d.and 'doclibrary_docs.state', 'public'
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'doclibrary_docs.category1_id' , params[:cat]
        d.and 'doclibrary_docs.section_code' , params[:gcd] unless params[:gcd].blank?
        d.and 'doclibrary_view_acl_docs.acl_flag' , 9
      }
    else

      sql.or {|d|
        d.and 'doclibrary_docs.state', 'public'
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'doclibrary_docs.category1_id' , params[:cat]
        d.and 'doclibrary_docs.section_code' , params[:gcd] unless params[:gcd].blank?
        d.and 'doclibrary_view_acl_docs.acl_flag' , 1
        d.and 'doclibrary_view_acl_docs.acl_section_code' , p_grp_code
      }

      sql.or {|d|
        d.and 'doclibrary_docs.state', 'public'
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'doclibrary_docs.category1_id' , params[:cat]
        d.and 'doclibrary_docs.section_code' , params[:gcd] unless params[:gcd].blank?
        d.and 'doclibrary_view_acl_docs.acl_flag' , 1
        d.and 'doclibrary_view_acl_docs.acl_section_code' , grp_code
      }

      sql.or {|d|
        d.and 'doclibrary_docs.state', 'public'
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'doclibrary_docs.category1_id' , params[:cat]
        d.and 'doclibrary_docs.section_code' , params[:gcd] unless params[:gcd].blank?
        d.and 'doclibrary_view_acl_docs.acl_flag' , 2
        d.and 'doclibrary_view_acl_docs.acl_user_code' , Site.user.code
      }
    end
    item = doclib_db_alias(Doclibrary::Doc)
    item = item.new
    item.page params[:page], params[:limit]
    @items = item.find(:all, :conditions=>sql.where, :order=>str_order, :select=>'doclibrary_docs.*' ,:joins => ['inner join doclibrary_view_acl_docs on doclibrary_docs.id = doclibrary_view_acl_docs.id'])
  end

  def norm_cat_index_form002
    str_order = "inpfld_001 , inpfld_002 DESC, inpfld_003 DESC, inpfld_004 DESC, inpfld_005, inpfld_006"
    item = doclib_db_alias(Doclibrary::Doc)
    item = item.new
    item.and :state, 'public'
    item.and :title_id, @title.id
    item.and :category1_id, params[:cat]
    item.page   params[:page], params[:limit]
    @items = item.find(:all, :order => str_order)
  end

  def normal_date_index
    parent_grp = Site.user.groups[0].parent unless Site.user.groups[0].blank?
    p_grp_code = ''
    p_grp_code = parent_grp.code unless parent_grp.blank?
    grp_code = ''
    grp_code = Site.user.groups[0].code unless Site.user.groups.blank?
    str_order = "doclibrary_docs.updated_at DESC, doclibrary_docs.created_at DESC, doclibrary_view_acl_docs.sort_no, doclibrary_docs.category1_id, doclibrary_docs.title"
    item = doclib_db_alias(Doclibrary::Doc)
    item = item.new
    search_cond = item.get_keywords_condition(params[:kwd], :body) unless params[:kwd].blank?
    sql = Condition.new

    sql.or {|d|
      d.and 'doclibrary_docs.title_id' , @title.id
      d.and 'doclibrary_docs.state', 'public'
      d.and 'doclibrary_docs.section_code' , params[:gcd] unless params[:gcd].blank?
      d.and 'doclibrary_docs.category1_id' , params[:cat] unless params[:cat].blank?
      d.and 'doclibrary_view_acl_docs.acl_flag' , 0
      d.and search_cond unless search_cond.blank?
    }
    if @is_admin

      sql.or {|d|
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'doclibrary_docs.state', 'public'
        d.and 'doclibrary_docs.section_code' , params[:gcd] unless params[:gcd].blank?
        d.and 'doclibrary_docs.category1_id' , params[:cat] unless params[:cat].blank?
        d.and 'doclibrary_view_acl_docs.acl_flag' , 9
        d.and search_cond unless search_cond.blank?
      }
    else

      sql.or {|d|
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'doclibrary_docs.state', 'public'
        d.and 'doclibrary_docs.section_code' , params[:gcd] unless params[:gcd].blank?
        d.and 'doclibrary_docs.category1_id' , params[:cat] unless params[:cat].blank?
        d.and 'doclibrary_view_acl_docs.acl_flag' , 1
        d.and 'doclibrary_view_acl_docs.acl_section_code' , p_grp_code
        d.and search_cond unless search_cond.blank?
      }

      sql.or {|d|
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'doclibrary_docs.state', 'public'
        d.and 'doclibrary_docs.section_code' , params[:gcd] unless params[:gcd].blank?
        d.and 'doclibrary_docs.category1_id' , params[:cat] unless params[:cat].blank?
        d.and 'doclibrary_view_acl_docs.acl_flag' , 1
        d.and 'doclibrary_view_acl_docs.acl_section_code' , grp_code
        d.and search_cond unless search_cond.blank?
      }

      sql.or {|d|
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'doclibrary_docs.state', 'public'
        d.and 'doclibrary_docs.section_code' , params[:gcd] unless params[:gcd].blank?
        d.and 'doclibrary_docs.category1_id' , params[:cat] unless params[:cat].blank?
        d.and 'doclibrary_view_acl_docs.acl_flag' , 2
        d.and 'doclibrary_view_acl_docs.acl_user_code' , Site.user.code
        d.and search_cond unless search_cond.blank?
      }
    end
    item.page params[:page], params[:limit]
    @items = item.find(:all, :conditions=>sql.where, :order=>str_order, :select=>'doclibrary_docs.*' ,:joins => ['inner join doclibrary_view_acl_docs on doclibrary_docs.id = doclibrary_view_acl_docs.id'])
  end

  def normal_draft_index

    params[:gcd] = Site.user_group.code unless @is_admin
    parent_grp = Site.user.groups[0].parent unless Site.user.groups[0].blank?
    p_grp_code = ''
    p_grp_code = parent_grp.code unless parent_grp.blank?
    grp_code = ''
    grp_code = Site.user.groups[0].code unless Site.user.groups.blank?
    str_section_code = ''
    str_section_code = params[:gcd].to_s unless params[:gcd].blank?
    str_order = "doclibrary_docs.updated_at DESC, doclibrary_docs.created_at DESC, doclibrary_view_acl_docs.sort_no, doclibrary_docs.category1_id, doclibrary_docs.title"
    item = doclib_db_alias(Doclibrary::Doc)
    item = item.new
    search_cond = item.get_keywords_condition(params[:kwd], :body) unless params[:kwd].blank?
    sql = Condition.new

    sql.or {|d|
      d.and 'doclibrary_docs.title_id' , @title.id
      d.and 'doclibrary_docs.state', 'draft'
      d.and 'doclibrary_docs.section_code' , str_section_code unless str_section_code.blank? unless @is_admin
      d.and 'doclibrary_view_acl_docs.acl_flag' , 0
      d.and search_cond unless search_cond.blank?
    }
    if @is_admin

      sql.or {|d|
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'doclibrary_docs.state', 'draft'
        d.and 'doclibrary_view_acl_docs.acl_flag' , 9
        d.and search_cond unless search_cond.blank?
      }
    else

      sql.or {|d|
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'doclibrary_docs.state', 'draft'
        d.and 'doclibrary_docs.section_code' , str_section_code unless str_section_code.blank?
        d.and 'doclibrary_view_acl_docs.acl_flag' , 1
        d.and 'doclibrary_view_acl_docs.acl_section_code' , p_grp_code
        d.and search_cond unless search_cond.blank?
      }

      sql.or {|d|
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'doclibrary_docs.state', 'draft'
        d.and 'doclibrary_docs.section_code' , str_section_code unless str_section_code.blank?
        d.and 'doclibrary_view_acl_docs.acl_flag' , 1
        d.and 'doclibrary_view_acl_docs.acl_section_code' , grp_code
        d.and search_cond unless search_cond.blank?
      }

      sql.or {|d|
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'doclibrary_docs.state', 'draft'
        d.and 'doclibrary_docs.section_code' , str_section_code unless str_section_code.blank?
        d.and 'doclibrary_view_acl_docs.acl_flag' , 2
        d.and 'doclibrary_view_acl_docs.acl_user_code' , Site.user.code
        d.and search_cond unless search_cond.blank?
      }
    end
    item.page   params[:page], params[:limit]
    @items = item.find(:all, :conditions=>sql.where, :order=>str_order, :select=>'doclibrary_docs.*' ,:joins => ['inner join doclibrary_view_acl_docs on doclibrary_docs.id = doclibrary_view_acl_docs.id'])
  end

  def recognize_index(no_paginate=nil)
    sql = Condition.new
    sql.or {|d|

      d.and "sql", "doclibrary_docs.state = 'recognize'"
      d.and "sql", "doclibrary_docs.section_code = '#{Site.user_group.code}'" unless @is_admin
    }
    sql.or {|d|

      d.and "sql", "doclibrary_docs.state = 'recognize'"
      d.and "sql", "doclibrary_recognizers.code = '#{Site.user.code}'"
    }
    join = "INNER JOIN doclibrary_recognizers ON doclibrary_docs.id = doclibrary_recognizers.parent_id AND doclibrary_docs.title_id = doclibrary_recognizers.title_id"
    item = doclib_db_alias(Doclibrary::Doc)
    item = item.new
    item.page(params[:page], params[:limit]) if no_paginate.blank?
    @items = item.find(:all,:select=>'doclibrary_docs.*', :joins=>join, :conditions=>sql.where,:order => 'latest_updated_at DESC', :group => 'doclibrary_docs.id')
  end

  def recognized_index
    str_state = 'recognized'

    parent_grp = Site.user.groups[0].parent unless Site.user.groups[0].blank?
    p_grp_code = ''
    p_grp_code = parent_grp.code unless parent_grp.blank?
    grp_code = ''
    grp_code = Site.user.groups[0].code unless Site.user.groups.blank?
    str_order = "doclibrary_docs.updated_at DESC, doclibrary_docs.created_at DESC, doclibrary_view_acl_docs.sort_no, doclibrary_docs.category1_id, doclibrary_docs.title"
    item = doclib_db_alias(Doclibrary::Doc)
    item = item.new
    search_cond = item.get_keywords_condition(params[:kwd], :body) unless params[:kwd].blank?
    sql = Condition.new

    sql.or {|d|
      d.and 'doclibrary_docs.title_id' , @title.id
      d.and 'doclibrary_docs.state', str_state
      d.and 'doclibrary_docs.section_code' , Site.user_group.code unless @is_admin
      d.and 'doclibrary_view_acl_docs.acl_flag' , 0
      d.and search_cond unless search_cond.blank?
    }
    if @is_admin

      sql.or {|d|
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'doclibrary_docs.state', str_state
        d.and 'doclibrary_view_acl_docs.acl_flag' , 9
        d.and search_cond unless search_cond.blank?
      }
    else

      sql.or {|d|
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'doclibrary_docs.state', str_state
        d.and 'doclibrary_docs.section_code' , Site.user_group.code
        d.and 'doclibrary_view_acl_docs.acl_flag' , 1
        d.and 'doclibrary_view_acl_docs.acl_section_code' , p_grp_code
        d.and search_cond unless search_cond.blank?
      }

      sql.or {|d|
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'doclibrary_docs.state', str_state
        d.and 'doclibrary_docs.section_code' , Site.user_group.code
        d.and 'doclibrary_view_acl_docs.acl_flag' , 1
        d.and 'doclibrary_view_acl_docs.acl_section_code' , grp_code
        d.and search_cond unless search_cond.blank?
      }

      sql.or {|d|
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'doclibrary_docs.state', str_state
        d.and 'doclibrary_docs.section_code' , Site.user_group.code
        d.and 'doclibrary_view_acl_docs.acl_flag' , 2
        d.and 'doclibrary_view_acl_docs.acl_user_code' , Site.user.code
        d.and search_cond unless search_cond.blank?
      }
    end
    item.page params[:page], params[:limit]
    @items = item.find(:all, :conditions=>sql.where, :order=>str_order, :select=>'doclibrary_docs.*' ,:joins => ['inner join doclibrary_view_acl_docs on doclibrary_docs.id = doclibrary_view_acl_docs.id'])
  end

  def normal_draft_index_form002
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
    item.and :title_id, @title.id
    item.and :level_no, level_no
    item.and :parent_id, parent_id
    item.page   params[:page], params[:limit]
    @folders = item.find(:all, :order=>"level_no, sort_no, id")

    str_order = "updated_at DESC, created_at DESC, category1_id, id" unless @title.form_name == 'form002'
    str_order = "inpfld_001 , inpfld_002 DESC, inpfld_003, inpfld_004, inpfld_005, inpfld_006" if @title.form_name == 'form002'
    item = doclib_db_alias(Doclibrary::Doc)
    item = item.new
    item.and :state, 'draft'
    item.and :title_id, @title.id
    item.and :category1_id, params[:cat]
    item.page   params[:page], params[:limit]
    @items = item.find(:all, :order => str_order)
  end

  def set_folder_level_code

    item = doclib_db_alias(Doclibrary::GroupFolder)
    item = item.new
    item.and :title_id, @title.id
    item.and :level_no, 1
    item.and :state, 'public'
    items = item.find(:all,:order => 'level_no, sort_no, parent_id, id')
    @group_levels = []
    set_folder_hash('group', items)

    item = doclib_db_alias(Doclibrary::Folder)
    item = item.new
    item.and :title_id, @title.id
    item.and :level_no, 1
    items = item.find(:all,:order => 'level_no, sort_no, parent_id, id')
    @category_levels = []
    set_folder_hash('category', items)
    Doclibrary::GroupFolder.remove_connection
  end

  def set_folder_hash(mode, items)
    if items.size > 0
      items.each do |item|
        if item.state == 'public'
          tree = '+'
          tree += "-" * (item.level_no - 2) if 0 < (item.level_no - 2)
          @group_levels << [tree + item.code + item.name, item.code] if mode == 'group'
          @category_levels << [tree + item.name, item.id] if 1 < item.level_no unless mode == 'group'
          if item.children.size > 0
              set_folder_hash(mode, item.children)
          end
        end
      end
    end
  end

  def section_folder_state_update
    group_item = doclib_db_alias(Doclibrary::GroupFolder)
    item = doclib_db_alias(Doclibrary::Doc)
    item = item.new
    item.and :state, 'public'
    item.and :title_id, @title.id
    item.find(:all, :select=>'section_code', :group => 'section_code').each do |code|
      g_item = group_item.new
      g_item.and :title_id, @title.id
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

  def form002_categories
    if @title.form_name == 'form002'
      @documents = []
      item = doclib_db_alias(Doclibrary::Category)
      item.find(:all, :conditions => {:state => 'public', :title_id => @title.id}, :order => 'id DESC').each do |dep|
        if dep.sono2.blank?
          str_sono = dep.sono.to_s
        else
          str_sono = "#{dep.sono.to_s} - #{dep.sono2.to_s}"
        end
        @documents << ["#{dep.wareki}#{dep.nen}年#{dep.gatsu}月その#{str_sono} : #{dep.filename}", dep.id]
      end
      Doclibrary::Category.remove_connection
    end
  end


  def set_form002_params
      item = doclib_db_alias(Doclibrary::Category)
      item = item.new
      item.and :id, @item.category2_id
      item = item.find(:first)
      if item
        @item.inpfld_001 = item.wareki
        @item.inpfld_002 = item.nen
        @item.inpfld_003 = item.gatsu
        @item.inpfld_004 = item.sono
        @item.inpfld_005 = item.sono2

        @item.inpfld_007 = "#{@item.inpfld_004.to_s} - #{item.sono2}" unless item.sono2.blank?
        @item.inpfld_007 = item.sono if item.sono2.blank?
      end
      Doclibrary::Category.remove_connection
  end

  def is_attach_new
    ret = false
    case @title.upload_system
    when 1..4
      ret = true
    end
    return ret
  end

  def return_form002_attached_url
    check = is_attach_new
    ret = ''
    item = doclib_db_alias(Doclibrary::File)
    item = item.new
    item.and :title_id, @item.title_id
    item.and :parent_id, @item.category2_id
    file = item.find(:first)
    unless file.blank?
      ret = "#{file.file_uri(file.system_name)}" if check
      ret = "/_admin/gwboard/receipts/#{file.id}/download_object?system=#{file.system_name}&title_id=#{file.title_id}" unless check
    end
    Doclibrary::File.remove_connection
    return ret
  end

  def set_recogusers
    @select_recognizers = {"1"=>'',"2"=>'',"3"=>'',"4"=>'',"5"=>''}
    i = 0
    for recoguser in @recogusers
      i += 1
      @select_recognizers[i.to_s] = recoguser.user_id.to_s
    end
  end

  def get_recogusers
    item = doclib_db_alias(Doclibrary::Recognizer)
    item = item.new
    item.and :title_id, @title.id
    item.and :parent_id, params[:id]
    item.order 'id'
    @recogusers = item.find(:all)
    Doclibrary::Recognizer.remove_connection
  end

  def publish_update
    item = doclib_db_alias(Doclibrary::Doc)
    item = item.new
    item.and :state, 'recognized'
    item.and :title_id, @title.id
    item.and :id, params[:id]

    item = item.find(:first)
    if item
      item.state = 'public'
      item.published_at = Time.now
      item.save
    end
    Doclibrary::Doc.remove_connection
    redirect_to(@title.docs_path)
  end

  def recognize_update
    item = doclib_db_alias(Doclibrary::Recognizer)
    item = item.new
    item.and :title_id, @title.id
    item.and :parent_id, params[:id]
    item.and :code, Site.user.code
    item = item.find(:first)
    if item
      item.recognized_at = Time.now
      item.save
    end

    item = doclib_db_alias(Doclibrary::Recognizer)
    item = item.new
    item.and :title_id, @title.id
    item.and :parent_id, params[:id]
    item.and "sql", "recognized_at IS NULL"
    item = item.find(:all)

    if item.length == 0
      item = doclib_db_alias(Doclibrary::Doc)
      item = item.find(params[:id])
      item.state = 'recognized'
      item.recognized_at = Time.now
      item.save

      user = System::User.find_by_code(item.editor_id.to_s)
      unless user.blank?
        Gw.add_memo(user.id.to_s, "#{@title.title}「#{item.title}」について、全ての承認が終了しました。", "次のボタンから記事を確認し,公開作業を行ってください。<br /></a><a href='#{item.show_path}&state=PUBLISH'><img src='/_common/themes/gw/files/bt_openconfirm.gif' alt='公開処理へ'></a>",{:is_system => 1})
      end
    end
    Doclibrary::Recognizer.remove_connection
    get_role_new
    redirect_to("#{@title.docs_path}") unless @is_writable
    redirect_to("#{@title.docs_path}&state=RECOGNIZE") if @is_writable
  end

  def check_recognize
    item = doclib_db_alias(Doclibrary::Recognizer)
    item = item.new
    item.and :title_id, @title.id
    item.and :parent_id, params[:id]
    item.and :code, Site.user.code
    item.and 'sql', "recognized_at is null"
    item = item.find(:all)
    ret = nil
    ret = true if item.length != 0
    Doclibrary::Recognizer.remove_connection
    return ret
  end

  def check_recognize_readable
    item = doclib_db_alias(Doclibrary::Recognizer)
    item = item.new
    item.and :title_id, @title.id
    item.and :parent_id, params[:id]
    item.and :code, Site.user.code
    item = item.find(:all)
    ret = nil
    ret = true if item.length != 0
    Doclibrary::Recognizer.remove_connection
    return ret
  end


  def sql_where
    sql = Condition.new
    sql.and :parent_id, @item.id
    sql.and :title_id, @item.title_id
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
    Doclibrary::Image.remove_connection
  end

  def destroy_atacched_files
    item = doclib_db_alias(Doclibrary::File)
    item.destroy_all(sql_where)
    Doclibrary::File.remove_connection
  end

  def destroy_files
    item = doclib_db_alias(Doclibrary::DbFile)
    item.destroy_all(sql_where)
    Doclibrary::DbFile.remove_connection
  end

end
