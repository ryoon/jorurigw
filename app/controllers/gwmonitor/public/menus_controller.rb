class Gwmonitor::Public::MenusController < ApplicationController

  include System::Controller::Scaffold
  include Gwmonitor::Model::Database
  include Gwmonitor::Controller::Systemname

  def initialize_scaffold
    @system_title = disp_system_name
    @css = ["/_common/themes/gw/css/monitor.css"]
    page_limit_default_setting
  end

  def index
    system_admin_flags

    sql = Condition.new

    sql.or {|d|
      d.and :state, 'draft' unless params[:cond] == 'already'
      d.and :state, 'public' if params[:cond] == 'already'
      d.and :send_division , 2
      d.and :user_code, Site.user.code
    }
    if params[:cond] == 'already'
      sql.or {|d|
        d.and :state, 'qNA'
        d.and :send_division , 2
        d.and :user_code, Site.user.code
      }
    end
    unless params[:cond] == 'already'
      sql.or {|d|
        d.and :state, 'closed'
        d.and :send_division , 2
        d.and :user_code, Site.user.code
      }
      sql.or {|d|
        d.and :state, 'editing'
        d.and :send_division , 2
        d.and :user_code, Site.user.code
      }
    end

    sql.or {|d|
      d.and :state, 'draft' unless params[:cond] == 'already'
      d.and :state, 'public' if params[:cond] == 'already'
      d.and :send_division , 1
      d.and :section_code, Site.user_group.code
    }
    if params[:cond] == 'already'
    sql.or {|d|
      d.and :state, 'qNA'
      d.and :send_division , 1
      d.and :section_code, Site.user_group.code
    }
    end
    unless params[:cond] == 'already'
      sql.or {|d|
        d.and :state, 'closed'
        d.and :send_division , 1
        d.and :section_code, Site.user_group.code
      }
      sql.or {|d|
        d.and :state, 'editing'
        d.and :send_division , 1
        d.and :section_code, Site.user_group.code
      }
    end
    item = Gwmonitor::Doc.new
    item.page(params[:page], params[:limit])
    @items = item.find(:all, :conditions=>sql.where, :order=>'expiry_date DESC, id DESC')
  end

end
