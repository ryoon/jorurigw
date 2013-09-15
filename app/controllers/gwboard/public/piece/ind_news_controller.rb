class Gwboard::Public::Piece::IndNewsController < ApplicationController

  def index
    piece_parms = params[:piece_param].split(/_/)
    return unless piece_parms.size == 3

    @system = piece_parms[0]
    title_id = piece_parms[1].to_i

    @limit_portal = piece_parms[2].to_i

    item = gwboard_news_control(@system)
    item = item.new
    item.and :state, 'public'
    item.and :id, title_id
    @title = item.find(:first)
    return if @title.blank?

    admin_flags(@title.id)
    get_writable_flag
    get_readable_flag
    unless @is_readable
      @title = nil
      return nil
    end

    case @system
    when 'gwbbs'
      gwbbs_qa_faq_index
    when 'gwfaq'
      gwbbs_qa_faq_index
    when 'gwqa'
      gwbbs_qa_faq_index
    when 'doclibrary'
      if @title.form_name == 'form001'
        doclibrary_form001_index
      else
        doclibrary_form002_index
      end
    when 'digitallibrary'
      digitallibrary_index
    end
  end

  def gwboard_docs_select_sql
    sql = ''
    if @system == 'gwbbs'
      sql = "'#{Time.now.strftime('%Y-%m-%d %H:%M')}:00' BETWEEN gwbbs_docs.able_date AND gwbbs_docs.expiry_date"
      if @title.restrict_access
        sql += " AND gwbbs_docs.section_code = '#{Site.user_group.code}'"
      end
    end
    return sql
  end

  def gwbbs_qa_faq_index
    item = gwboard_news_doc(@system, @title.id)
    item = item.new
    item.and :state, 'public'

    item.and(:doc_type, 0)  if @system =='gwqa'

    sql = gwboard_docs_select_sql
    item.and 'sql', sql unless sql.blank?

    item.and :title_id, @title.id
    item.order  'latest_updated_at DESC, id'
    item.page 1, ( @limit_portal + 1 )
    @items = item.find(:all)

    gwboard_news_doc_close(@system)
  end

  def digitallibrary_index
    item = gwboard_news_doc(@system, @title.id)
    item = item.new
    item.and :state, 'public'
    item.and :doc_type, 1
    item.and :title_id, @title.id
    str_order = "latest_updated_at DESC, level_no, sort_no, id"
    item.page 1, ( @limit_portal + 1 )
    @items = item.find(:all, :order=> str_order)

    gwboard_news_doc_close(@system)
  end

  def doclibrary_form002_index
    str_order = "updated_at DESC, inpfld_001 , inpfld_002 DESC, inpfld_003 DESC, inpfld_004 DESC, inpfld_005, inpfld_006"
    item = gwboard_news_doc(@system, @title.id)
    item = item.new
    item.and :state, 'public'
    item.and :title_id, @title.id
    item.page 1, ( @limit_portal + 1 )
    @items = item.find(:all, :order => str_order)

    gwboard_news_doc_close(@system)
  end

  def doclibrary_form001_index
    p_grp_code = ''
    p_grp_code = Site.user_group.parent.code unless Site.user_group.parent.blank?
    grp_code = ''
    grp_code = Site.user_group.code
    str_order = "doclibrary_docs.updated_at DESC, doclibrary_docs.created_at DESC, doclibrary_view_acl_docs.sort_no, doclibrary_docs.category1_id, doclibrary_docs.title"

    item = gwboard_news_doc(@system, @title.id)
    item = item.new
    sql = Condition.new

    sql.or {|d|
      d.and 'doclibrary_docs.title_id' , @title.id
      d.and 'doclibrary_docs.state', 'public'
      d.and 'doclibrary_view_acl_docs.acl_flag' , 0
    }
    if @is_admin

      sql.or {|d|
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'doclibrary_docs.state', 'public'
        d.and 'doclibrary_view_acl_docs.acl_flag' , 9
      }
    else

      sql.or {|d|
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'doclibrary_docs.state', 'public'
        d.and 'doclibrary_view_acl_docs.acl_flag' , 1
        d.and 'doclibrary_view_acl_docs.acl_section_code' , p_grp_code
      }

      sql.or {|d|
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'doclibrary_docs.state', 'public'
        d.and 'doclibrary_view_acl_docs.acl_flag' , 1
        d.and 'doclibrary_view_acl_docs.acl_section_code' , grp_code
      }

      sql.or {|d|
        d.and 'doclibrary_docs.title_id' , @title.id
        d.and 'doclibrary_docs.state', 'public'
        d.and 'doclibrary_view_acl_docs.acl_flag' , 2
        d.and 'doclibrary_view_acl_docs.acl_user_code' , Site.user.code
      }
    end
    item.page 1, ( @limit_portal + 1 )
    @items = item.find(:all, :conditions=>sql.where, :order=>str_order, :select=>'doclibrary_docs.*' ,:joins => ['inner join doclibrary_view_acl_docs on doclibrary_docs.id = doclibrary_view_acl_docs.id'])

    gwboard_news_doc_close(@system)
  end

  def gwboard_news_control(system)
    case system
    when 'gwbbs'
      sys = Gwbbs::Control
    when 'gwfaq'
      sys = Gwfaq::Control
    when 'gwqa'
      sys = Gwqa::Control
    when 'doclibrary'
      sys = Doclibrary::Control
    when 'digitallibrary'
      sys = Digitallibrary::Control
    else
    end
    return sys
  end

  def gwboard_news_doc(system, title_id)
    case system
    when 'gwbbs'
      sys = Gwbbs::Doc
    when 'gwfaq'
      sys = Gwfaq::Doc
    when 'gwqa'
      sys = Gwqa::Doc
    when 'doclibrary'
      sys = Doclibrary::Doc
    when 'digitallibrary'
      sys = Digitallibrary::Doc
    else
    end
    return gwboard_db_alias2(sys, title_id)
  end

  def gwboard_news_doc_close(system)
    case system
    when 'gwbbs'
      Gwbbs::Doc.remove_connection
    when 'gwfaq'
      Gwfaq::Doc.remove_connection
    when 'gwqa'
      Gwqa::Doc.remove_connection
    when 'doclibrary'
      Doclibrary::Doc.remove_connection
    when 'digitallibrary'
      Digitallibrary::Doc.remove_connection
    else
    end
  end

  def gwboard_db_alias2(item, title_id)

    cnn = item.establish_connection

    cn = cnn.spec.config[:database]

    dbname = ''
    dbname = @title.dbname unless @title.blank?
    unless dbname == ''
      cnn.spec.config[:database] = @title.dbname.to_s
    else
      dbstr = ''
      dbstr = '_qa' if item.table_name.index("gwqa_")
      dbstr = '_bbs' if item.table_name.index("gwbbs_")
      dbstr = '_faq' if item.table_name.index("gwfaq_")
      dbstr = '_doc' if item.table_name.index("doclibrary_")
      dbstr = '_dig' if item.table_name.index("digitallibrary_")

      l = 0
      l = cn.length if cn
      if l != 0
        i = cn.rindex "_", cn.length
        cnn.spec.config[:database] = cn[0,i] + dbstr
      else
        cnn.spec.config[:database] = "development_jgw" + dbstr
      end

      unless title_id.blank?
        if is_integer(title_id)
          cnn.spec.config[:database] +=  '_' + sprintf("%06d", title_id)
        end
      end
    end
    item::Gwboard::CommonDb.establish_connection(cnn.spec)

    return item

  end

  def item_system_adm
    case @system
    when 'gwbbs'
      sys = Gwbbs::Adm
    when 'gwfaq'
      sys = Gwfaq::Adm
    when 'gwqa'
      sys = Gwqa::Adm
    when 'doclibrary'
      sys = Doclibrary::Adm
    when 'digitallibrary'
      sys = Digitallibrary::Adm
    else
    end
    return sys
  end
  def admin_flags(title_id)
    @is_sysadm = true if System::Model::Role.get(1, Site.user.id ,@system, 'admin')
    @is_sysadm = true if System::Model::Role.get(2, Site.user_group.id ,@system, 'admin') unless @is_sysadm
    @is_bbsadm = true if @is_sysadm

    unless @is_bbsadm
      item = item_system_adm
      item = item.new
      item.and :user_id, 0
      item.and :group_code, Site.user_group.code
      item.and :title_id, title_id unless title_id == '_menu'
      items = item.find(:all)
      @is_bbsadm = true unless items.blank?

      unless @is_bbsadm
        item = item_system_adm
        item = item.new
        item.and :user_code, Site.user.code
        item.and :group_code, Site.user_group.code
        item.and :title_id, title_id unless title_id == '_menu'
        items = item.find(:all)
        @is_bbsadm = true unless items.blank?
      end
    end

    @is_admin = true if @is_sysadm
    @is_admin = true if @is_bbsadm
  end

  def item_system_role
    case @system
    when 'gwbbs'
      sys = Gwbbs::Role
    when 'gwfaq'
      sys = Gwfaq::Role
    when 'gwqa'
      sys = Gwqa::Role
    when 'doclibrary'
      sys = Doclibrary::Role
    when 'digitallibrary'
      sys = Digitallibrary::Role
    else
    end
    return sys
  end

  def get_writable_flag
    @is_writable = true if @is_admin
    unless @is_writable
      sql = Condition.new
      sql.and :role_code, 'w'
      sql.and :title_id, @title.id
      r_item = item_system_role
      items = r_item.find(:all, :order=>'group_code', :conditions => sql.where)
      items.each do |item|
        @is_writable = true if item.group_code == '0'
        for group in Site.user.groups
          @is_writable = true if item.group_code == group.code
          @is_writable = true if item.group_code == group.parent.code unless group.parent.blank?
          break if @is_writable
        end
        break if @is_writable
      end
    end

    unless @is_writable
      item = item_system_role
      item = item.new
      item.and :role_code, 'w'
      item.and :title_id, @title.id
      item.and :user_code, Site.user.code
      item = item.find(:first)
      @is_writable = true if item.user_code == Site.user.code unless item.blank?
    end
  end

  def get_readable_flag
    @is_readable = true if @is_admin
    unless @is_readable
      sql = Condition.new
      sql.and :role_code, 'r'
      sql.and :title_id, @title.id
      sql.and 'sql', 'user_id IS NULL'
      r_item = item_system_role
      items = r_item.find(:all, :order=>'group_code', :conditions => sql.where)
      items.each do |item|
        @is_readable = true if item.group_code == '0'

        for group in Site.user.groups
          @is_readable = true if item.group_code == group.code
          @is_readable = true if item.group_code == group.parent.code unless group.parent.blank?
          break if @is_readable
        end
        break if @is_readable
      end
    end

    unless @is_readable
      item = item_system_role
      item = item.new
      item.and :role_code, 'r'
      item.and :title_id, @title.id
      item.and :user_code, Site.user.code
      item = item.find(:first)
      @is_readable = true if item.user_code == Site.user.code unless item.blank?
    end
  end

  def is_integer(no)
    if no == nil
      return false
    else
      begin
        Integer(no)
      rescue
        return false
      end
    end
  end


end