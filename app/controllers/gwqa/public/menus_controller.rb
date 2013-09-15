class Gwqa::Public::MenusController < ApplicationController
  include Gwboard::Controller::Scaffold
  include Gwqa::Model::DbnameAlias
  include Gwboard::Controller::Authorize

  def initialize_scaffold
    @css = ["/_common/themes/gw/css/gwqa.css"]
  end

  def index
    admin_flags('_menu')
    if @is_sysadm
      admin_index
    else
      readable_index
    end
  end

  def admin_index
    item = Gwqa::Control.new
    item.and :view_hide , 1
    item.page   params[:page], params[:limit]
    item.and :state, 'public'
    @items = item.find(:all, :order => 'sort_no , docslast_updated_at DESC')
  end

  def readable_index

    sql = Condition.new
    sql.or {|d|
      d.and :state, 'public'
      d.and :view_hide , 1
      d.and "sql", "gwqa_roles.role_code = 'r'"
      d.and "sql", "gwqa_roles.group_code = '0'"
    }

    for group in Site.user.groups
      sql.or {|d|
        d.and :state, 'public'
        d.and :view_hide , 1
        d.and "sql", "gwqa_roles.role_code = 'r'"
        d.and "sql", "gwqa_roles.group_code = '#{group.code}'"
      }

      unless group.parent.blank?
        sql.or {|d|
          d.and :state, 'public'
          d.and :view_hide , 1
          d.and "sql", "gwqa_roles.role_code = 'r'"
          d.and "sql", "gwqa_roles.group_code = '#{group.parent.code}'"
        }
      end
    end

    sql.or {|d|
      d.and :state, 'public'
      d.and :view_hide , 1
      d.and "sql", "gwqa_roles.role_code = 'r'"
      d.and "sql", "gwqa_roles.user_code = '#{Site.user.code}'"
    }
    join = "INNER JOIN gwqa_roles ON gwqa_controls.id = gwqa_roles.title_id"
    item = Gwqa::Control.new
    item.page   params[:page], params[:limit]
    menu_order = "sort_no , docslast_updated_at DESC "
    @items = item.find(:all, :joins=>join, :conditions=>sql.where,:order => menu_order, :group => 'gwqa_controls.id')
  end

end
