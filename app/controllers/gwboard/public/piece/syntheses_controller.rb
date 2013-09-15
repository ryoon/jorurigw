class Gwboard::Public::Piece::SynthesesController < ApplicationController
  include Gwboard::Controller::Scaffold
  include Gwboard::Controller::Authorize

  def initialize_scaffold
    item = Gwboard::Synthesetup.new
    item.and :content_id, 0
    @select = item.find(:first)

    item = Gwboard::Synthesetup.new
    item.and :content_id, 2
    item = item.find(:first)
    limit_date = ''
    limit_date = item.limit_date  unless item.blank?
    case limit_date
    when 'today'
      @msg = '本日'
      @date = Date.today.strftime('%Y-%m-%d')
    when 'yesterday'
      @msg = '前日から'
      @date = Date.yesterday.strftime('%Y-%m-%d')
    when '3.days'
      @msg = '3日前から'
      @date = 3.days.ago.strftime('%Y-%m-%d')
    when '4.days'
      @msg = '4日前から'
      @date = 4.days.ago.strftime('%Y-%m-%d')
    else
      @msg = '本日'
      @date = Date.yesterday.strftime('%Y-%m-%d')
    end
    @date = @date + " 00:00:00"
  end

  def index
    index_gwbbs if @select.gwbbs_check  unless @select.blank?
    index_gwfaq if @select.gwfaq_check  unless @select.blank?
    index_gwqa  if @select.gwqa_check  unless @select.blank?
    index_doc_plus_admin  if @select.doclib_check  unless @select.blank?
    index_digitallib  if @select.digitallib_check  unless @select.blank?

    @none_dsp = true
    @none_dsp = false unless @bbs_docs.blank?
    @none_dsp = false unless @faq_docs.blank?
    @none_dsp = false unless @qa_docs.blank?
    @none_dsp = false unless @doclib_docs.blank?
    @none_dsp = false unless @digitallib_docs.blank?
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
    items = item.find(:all, :joins=>join, :conditions=>sql.where, :group => s_group,:select => 'latest_updated_at',:order=>'gwboard_syntheses.latest_updated_at DESC')
    @bbs_docs = "#{@msg} #{items.length}件の更新あり。最新記事は [ #{items[0].latest_updated_at.strftime('%Y年%m月%d日 %H時%M分').to_s} ] に更新。" if items.length > 0
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
    items = item.find(:all, :joins=>join, :conditions=>sql.where, :group => s_group,:select => 'latest_updated_at',:order=>'gwboard_syntheses.latest_updated_at DESC')
    @faq_docs = "#{@msg} #{items.length}件の更新あり。最新記事は [ #{items[0].latest_updated_at.strftime('%Y年%m月%d日 %H時%M分').to_s} ] に更新。" if items.length > 0
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
    items = item.find(:all, :joins=>join, :conditions=>sql.where, :group => s_group,:select => 'latest_updated_at',:order=>'gwboard_syntheses.latest_updated_at DESC')
    @qa_docs = "#{@msg} #{items.length}件の更新あり。最新記事は [ #{items[0].latest_updated_at.strftime('%Y年%m月%d日 %H時%M分').to_s} ] に更新。" if items.length > 0
  end

  def index_doc_plus_admin
    index_doclib

    dsp_count = 0
    dsp_date = ''
    unless @doclib_items.blank?
      dsp_count = @doclib_items.length
      dsp_date = @doclib_items[0].latest_updated_at.strftime('%Y年%m月%d日 %H時%M分')
    end

    @doclib_docs = "#{@msg} #{dsp_count}件の更新あり。最新記事は [ #{dsp_date} ] に更新。" unless dsp_count == 0
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
    @doclib_items = item.find(:all, :joins=>join, :conditions=>sql.where, :group => s_group,:select => 'latest_updated_at',:order=>'gwboard_syntheses.latest_updated_at DESC')
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
    items = item.find(:all, :joins=>join, :conditions=>sql.where, :group => s_group,:select => 'latest_updated_at',:order=>'gwboard_syntheses.latest_updated_at DESC')
    @digitallib_docs = "#{@msg} #{items.length}件の更新あり。最新記事は [ #{items[0].latest_updated_at.strftime('%Y年%m月%d日 %H時%M分').to_s} ] に更新。" if items.length > 0
  end
end
