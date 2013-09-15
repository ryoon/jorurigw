class Gwboard::Public::SynthesesController < ApplicationController
  include Gwboard::Controller::Scaffold
  include Gwboard::Controller::Authorize

  def initialize_scaffold
    item = Gwboard::Synthesetup.new
    item.and :content_id, 2
    item = item.find(:first)
    limit_date = ''
    limit_date = item.limit_date  unless item.blank?
    case limit_date
    when 'today'
      @date = Date.today.strftime('%Y-%m-%d')
    when 'yesterday'
      @date = Date.yesterday.strftime('%Y-%m-%d')
    when '3.days'
      @date = 3.days.ago.strftime('%Y-%m-%d')
    when '4.days'
      @date = 4.days.ago.strftime('%Y-%m-%d')
    else
      @date = Date.yesterday.strftime('%Y-%m-%d')
    end
    @css = ["/_common/themes/gw/css/gwbbs_standard.css"]
    @date = @date + " 00:00:00"
    params[:limit] = 50
  end

  def index
    case params[:system].to_s
    when 'gwbbs'
      index_gwbbs
    when 'gwfaq'
      index_gwfaq
    when 'gwqa'
      index_gwqa
    when 'doclibrary'
      index_doclib
      index_adminlib
    when 'digitallibrary'
      index_digitallib
    else
      params[:system] = 'gwbbs'
      index_gwbbs
    end
  end

  def index_gwbbs
    sql = Condition.new

    sql.or {|d|
      d.and :state, 'public'
      d.and :system_name , 'gwbbs'
      d.and :latest_updated_at , '>=' , @date
      d.and "sql", "gwbbs_roles.role_code = 'r'"
      d.and "sql", "gwbbs_roles.group_code = '0'"
      d.and "sql", "'" + Time.now.strftime("%Y/%m/%d %H:%M:%S") + "' between gwboard_syntheses.able_date AND gwboard_syntheses.expiry_date"
    }

    sql.or {|d|
      d.and :state, 'public'
      d.and :system_name , 'gwbbs'
      d.and :latest_updated_at , '>=' , @date
      d.and "sql", "gwbbs_roles.role_code = 'r'"
      d.and "sql", "gwbbs_roles.group_code = '#{Site.user_group.code}'"
      d.and "sql", "'" + Time.now.strftime("%Y/%m/%d %H:%M:%S") + "' between gwboard_syntheses.able_date AND gwboard_syntheses.expiry_date"
    }

    sql.or {|d|
      d.and :state, 'public'
      d.and :system_name , 'gwbbs'
      d.and :latest_updated_at , '>=' , @date
      d.and "sql", "gwbbs_roles.role_code = 'r'"
      d.and "sql", "gwbbs_roles.user_code = '#{Site.user.code}'"
      d.and "sql", "'" + Time.now.strftime("%Y/%m/%d %H:%M:%S") + "' between gwboard_syntheses.able_date AND gwboard_syntheses.expiry_date"
    }
    join = "INNER JOIN gwbbs_roles ON gwboard_syntheses.title_id = gwbbs_roles.title_id"
    s_group = 'gwboard_syntheses.id'
    item = Gwboard::Synthesis.new
    item.page   params[:page], params[:limit]
    @items = item.find(:all, :joins=>join, :conditions=>sql.where, :group => s_group,:select => 'gwboard_syntheses.*',:order=>'gwboard_syntheses.latest_updated_at DESC')
  end

  def index_gwfaq
    sql = Condition.new
    sql.or {|d|
      d.and :state, 'public'
      d.and :system_name , 'gwfaq'
      d.and :latest_updated_at , '>=' , @date
      d.and "sql", "gwfaq_roles.role_code = 'r'"
      d.and "sql", "gwfaq_roles.group_code = '0'"
    }

    sql.or {|d|
      d.and :state, 'public'
      d.and :system_name , 'gwfaq'
      d.and :latest_updated_at , '>=' , @date
      d.and "sql", "gwfaq_roles.role_code = 'r'"
      d.and "sql", "gwfaq_roles.group_code = '#{Site.user_group.code}'"
    }
    join = "INNER JOIN gwfaq_roles ON gwboard_syntheses.title_id = gwfaq_roles.title_id"
    s_group = 'gwboard_syntheses.id'
    item = Gwboard::Synthesis.new
    item.page   params[:page], params[:limit]
    @items = item.find(:all, :joins=>join, :conditions=>sql.where, :group => s_group,:select => 'gwboard_syntheses.*',:order=>'gwboard_syntheses.latest_updated_at DESC')
  end

  def index_gwqa
    sql = Condition.new

    sql.or {|d|
      d.and :state, 'public'
      d.and :system_name , 'gwqa'
      d.and :latest_updated_at , '>=' , @date
      d.and "sql", "gwqa_roles.role_code = 'r'"
      d.and "sql", "gwqa_roles.group_code = '0'"
    }

    sql.or {|d|
      d.and :state, 'public'
      d.and :system_name , 'gwqa'
      d.and :latest_updated_at , '>=' , @date
      d.and "sql", "gwqa_roles.role_code = 'r'"
      d.and "sql", "gwqa_roles.group_code = '#{Site.user_group.code}'"
    }
    join = "INNER JOIN gwqa_roles ON gwboard_syntheses.title_id = gwqa_roles.title_id"
    s_group = 'gwboard_syntheses.id'
    item = Gwboard::Synthesis.new
    item.page   params[:page], params[:limit]
    @items = item.find(:all, :joins=>join, :conditions=>sql.where, :group => s_group,:select => 'gwboard_syntheses.*',:order=>'gwboard_syntheses.latest_updated_at DESC')
  end

  def index_doclib
    sql = Condition.new

    sql.or {|d|
      d.and :state, 'public'
      d.and :system_name , 'doclibrary'
      d.and :latest_updated_at , '>=' , @date
      d.and "sql", "doclibrary_roles.role_code = 'r'"
      d.and "sql", "doclibrary_roles.group_code = '0'"
      d.and "sql", "gwboard_syntheses.acl_flag = 0"
    }

    sql.or {|d|
      d.and :state, 'public'
      d.and :system_name , 'doclibrary'
      d.and :latest_updated_at , '>=' , @date
      d.and "sql", "doclibrary_roles.role_code = 'r'"
      d.and "sql", "doclibrary_roles.group_code = '#{Site.user_group.code}'"
      d.and "sql", "gwboard_syntheses.acl_flag = 0"
    }

    unless Site.user_group.parent.blank?
      sql.or {|d|
        d.and :state, 'public'
        d.and :system_name , 'doclibrary'
        d.and :latest_updated_at , '>=' , @date
        d.and "sql", "doclibrary_roles.role_code = 'r'"
        d.and "sql", "doclibrary_roles.group_code = '#{Site.user_group.parent.code}'"
        d.and "sql", "gwboard_syntheses.acl_flag = 0"
      }
    end

    unless Site.user_group.parent.blank?
      sql.or {|d|
        d.and :state, 'public'
        d.and :system_name , 'doclibrary'
        d.and :latest_updated_at , '>=' , @date
        d.and "sql", "doclibrary_roles.role_code = 'r'"
        d.and "sql", "gwboard_syntheses.acl_flag = 1"
        d.and "sql", "gwboard_syntheses.acl_section_code = '#{Site.user_group.parent.code}'"
      }
    end

    sql.or {|d|
      d.and :state, 'public'
      d.and :system_name , 'doclibrary'
      d.and :latest_updated_at , '>=' , @date
      d.and "sql", "doclibrary_roles.role_code = 'r'"
      d.and "sql", "gwboard_syntheses.acl_flag = 1"
      d.and "sql", "gwboard_syntheses.acl_section_code = '#{Site.user_group.code}'"
    }

    sql.or {|d|
      d.and :state, 'public'
      d.and :system_name , 'doclibrary'
      d.and :latest_updated_at , '>=' , @date
      d.and "sql", "doclibrary_roles.role_code = 'r'"
      d.and "sql", "gwboard_syntheses.acl_flag = 2"
      d.and "sql", "gwboard_syntheses.acl_user_code = '#{Site.user.code}'"
    }
    join = "INNER JOIN doclibrary_roles ON gwboard_syntheses.title_id = doclibrary_roles.title_id"
    s_group = 'gwboard_syntheses.title_id, gwboard_syntheses.parent_id'
    item = Gwboard::Synthesis.new
    item.page   params[:page], params[:limit]
    @items = item.find(:all, :joins=>join, :conditions=>sql.where, :group => s_group,:select => 'gwboard_syntheses.*',:order=>'gwboard_syntheses.latest_updated_at DESC')
  end

  def index_adminlib
    sql = Condition.new

    sql.or {|d|
      d.and :state, 'public'
      d.and :system_name , 'adminlibrary'
      d.and :latest_updated_at , '>=' , @date
      d.and "sql", "adminlibrary_roles.role_code = 'r'"
      d.and "sql", "adminlibrary_roles.group_code = '0'"
    }

    sql.or {|d|
      d.and :state, 'public'
      d.and :system_name , 'adminlibrary'
      d.and :latest_updated_at , '>=' , @date
      d.and "sql", "adminlibrary_roles.role_code = 'r'"
      d.and "sql", "adminlibrary_roles.group_code = '#{Site.user_group.code}'"
    }
    join = "INNER JOIN adminlibrary_roles ON gwboard_syntheses.title_id = adminlibrary_roles.title_id"
    s_group = 'gwboard_syntheses.id'
    item = Gwboard::Synthesis.new
    item.page   params[:page], params[:limit]
    @admin_items = item.find(:all, :joins=>join, :conditions=>sql.where, :group => s_group,:select => 'gwboard_syntheses.*',:order=>'gwboard_syntheses.latest_updated_at DESC')
  end

  def index_digitallib
    sql = Condition.new

    sql.or {|d|
      d.and :state, 'public'
      d.and :system_name , 'digitallibrary'
      d.and :latest_updated_at , '>=' , @date
      d.and "sql", "digitallibrary_roles.role_code = 'r'"
      d.and "sql", "digitallibrary_roles.group_code = '0'"
    }

    sql.or {|d|
      d.and :state, 'public'
      d.and :system_name , 'digitallibrary'
      d.and :latest_updated_at , '>=' , @date
      d.and "sql", "digitallibrary_roles.role_code = 'r'"
      d.and "sql", "digitallibrary_roles.group_code = '#{Site.user_group.code}'"
    }
    join = "INNER JOIN digitallibrary_roles ON gwboard_syntheses.title_id = digitallibrary_roles.title_id"
    s_group = 'gwboard_syntheses.id'
    item = Gwboard::Synthesis.new
    item.page   params[:page], params[:limit]
    @items = item.find(:all, :joins=>join, :conditions=>sql.where, :group => s_group,:select => 'gwboard_syntheses.*',:order=>'gwboard_syntheses.latest_updated_at DESC')
  end

end