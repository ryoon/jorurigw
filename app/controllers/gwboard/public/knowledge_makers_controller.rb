class Gwboard::Public::KnowledgeMakersController < ApplicationController
  include Gwboard::Controller::Scaffold
  include Gwboard::Model::KbdbnameAlias
  include Gwboard::Controller::Authorize

  def initialize_scaffold
     @system = 'gwfaq'
     @css = ["/_common/themes/gw/css/gwfaq.css"]
  end

  def index
    faq_index
    qa_index
  end

  def faq_index
    faq_admin_flags('_menu')
    @is_faq_admin = @is_admin
    if @is_sysadm
      faq_sysadm_index
    else
      faq_bbsadm_index
    end
  end

  def faq_sysadm_index
    hide = false
    hide = true if params[:state] == "HIDE"
    item = Gwfaq::Control.new
    item.and :view_hide , 0 if hide
    item.and :view_hide , 1 unless hide
    item.page  params[:page], params[:limit]
    @faq_items = item.find(:all,:order => 'sort_no, updated_at DESC')
  end

  def faq_bbsadm_index
    hide = false
    hide = true if params[:state] == "HIDE"

    sql = Condition.new
    sql.or {|d|
      d.and "sql", "gwfaq_controls.state = 'public'"
      d.and "sql", "gwfaq_controls.view_hide = 0" if hide
      d.and "sql", "gwfaq_controls.view_hide = 1" unless hide
      d.and "sql", "gwfaq_adms.user_code = '#{Site.user.code}'"
    }

    sql.or {|d|
      d.and "sql", "gwfaq_controls.state = 'public'"
      d.and "sql", "gwfaq_controls.view_hide = 0" if hide
      d.and "sql", "gwfaq_controls.view_hide = 1" unless hide
      d.and "sql", "gwfaq_adms.user_id = 0"
      d.and "sql", "gwfaq_adms.group_code = '#{Site.user_group.code}'"
    }

    sql.or {|d|
      d.and "sql", "gwfaq_controls.state = 'public'"
      d.and "sql", "gwfaq_controls.view_hide = 0" if hide
      d.and "sql", "gwfaq_controls.view_hide = 1" unless hide
      d.and "sql", "gwfaq_adms.user_id = 0"
      d.and "sql", "gwfaq_adms.group_code = '#{parent_group_code}'"
    }

    join = "INNER JOIN gwfaq_adms ON gwfaq_controls.id = gwfaq_adms.title_id"
    item = Gwfaq::Control.new
    item.page   params[:page], params[:limit]
    @faq_items = item.find(:all, :joins=>join, :conditions=>sql.where,:order => 'sort_no, updated_at DESC', :group => 'gwfaq_controls.id')
  end

  def qa_index
    qa_admin_flags('_menu')
    @is_qa_admin = @is_admin
    if @is_sysadm
      qa_sysadm_index
    else
      qa_bbsadm_index
    end
  end

  def qa_sysadm_index
    hide = false
    hide = true if params[:state] == "HIDE"
    item = Gwqa::Control.new
    item.and :view_hide , 0 if hide
    item.and :view_hide , 1 unless hide
    item.page  params[:page], params[:limit]
    @qa_items = item.find(:all,:order => 'sort_no, updated_at DESC')
  end

  def qa_bbsadm_index
    hide = false
    hide = true if params[:state] == "HIDE"

    sql = Condition.new
    sql.or {|d|
      d.and "sql", "gwqa_controls.state = 'public'"
      d.and "sql", "gwqa_controls.view_hide = 0" if hide
      d.and "sql", "gwqa_controls.view_hide = 1" unless hide
      d.and "sql", "gwqa_adms.user_code = '#{Site.user.code}'"
    }
    sql.or {|d|
      d.and "sql", "gwqa_controls.state = 'public'"
      d.and "sql", "gwqa_controls.view_hide = 0" if hide
      d.and "sql", "gwqa_controls.view_hide = 1" unless hide
      d.and "sql", "gwqa_adms.user_id = 0"
      d.and "sql", "gwqa_adms.group_code = '#{Site.user_group.code}'"
    }
    sql.or {|d|
      d.and "sql", "gwqa_controls.state = 'public'"
      d.and "sql", "gwqa_controls.view_hide = 0" if hide
      d.and "sql", "gwqa_controls.view_hide = 1" unless hide
      d.and "sql", "gwqa_adms.user_id = 0"
      d.and "sql", "gwqa_adms.group_code = '#{parent_group_code}'"
    }
    join = "INNER JOIN gwqa_adms ON gwqa_controls.id = gwqa_adms.title_id"
    item = Gwqa::Control.new
    item.page   params[:page], params[:limit]
    @qa_items = item.find(:all, :joins=>join, :conditions=>sql.where,:order => 'sort_no, updated_at DESC', :group => 'gwqa_controls.id')
  end

end
