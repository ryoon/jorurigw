class Doclibrary::Public::MenusController < ApplicationController
  include Gwboard::Controller::Scaffold
  include Doclibrary::Model::DbnameAlias
  include Gwboard::Controller::Authorize

  def initialize_scaffold
    @css = ["/_common/themes/gw/css/doclibrary.css"]
    params[:limit] = 100
  end

  def index
    admin_flags('_menu')
    if @is_sysadm
      admin_index
      admin_index_adminlibrary
    else
      readable_index
      readable_index_adminlibrary
    end
  end

  def admin_index
    item = Doclibrary::Control.new
    item.and :state, 'public'
    item.and :view_hide , 1
    item.page   params[:page], params[:limit]
    @items = item.find(:all, :order => 'sort_no , docslast_updated_at DESC , updated_at DESC')
  end

  def readable_index

    sql = Condition.new

    sql.or {|d|
      d.and :state, 'public'
      d.and :view_hide , 1
      d.and "sql", "doclibrary_roles.role_code = 'r'"
      d.and "sql", "doclibrary_roles.group_code = '0'"
    }

    for group in Site.user.groups
      sql.or {|d|
        d.and :state, 'public'
        d.and :view_hide , 1
        d.and "sql", "doclibrary_roles.role_code = 'r'"
        d.and "sql", "doclibrary_roles.group_code = '#{group.code}'"
      }

      unless group.parent.blank?
        sql.or {|d|
          d.and :state, 'public'
          d.and :view_hide , 1
          d.and "sql", "doclibrary_roles.role_code = 'r'"
          d.and "sql", "doclibrary_roles.group_code = '#{group.parent.code}'"
        }
      end

      sql.or {|d|
        d.and :state, 'public'
        d.and :view_hide , 1
        d.and "sql", "doclibrary_roles.role_code = 'r'"
        d.and "sql", "doclibrary_roles.user_code = '#{Site.user.code}'"
      }
    end
    join = "INNER JOIN doclibrary_roles ON doclibrary_controls.id = doclibrary_roles.title_id"
    item = Doclibrary::Control.new
    item.page   params[:page], params[:limit]
    menu_order = "sort_no , docslast_updated_at DESC "
    @items = item.find(:all, :joins=>join, :conditions=>sql.where,:order => menu_order, :group => 'doclibrary_controls.id')
  end


  def admin_index_adminlibrary
  	@admin_items = {}
  end

  def readable_index_adminlibrary
    c1 = Condition.new
    c1.and :view_hide , 1
    c1.and "sql", "adminlibrary_roles.role_code = 'r'"
    c1.and "sql", "adminlibrary_roles.group_code = '0'"

    c2 = Condition.new
    c2.and :view_hide , 1
    c2.and "sql", "adminlibrary_roles.role_code = 'r'"
    c2.and "sql", "adminlibrary_roles.group_code = '#{Site.user_group.code}'"

    parent_code = parent_group_code
    if parent_code
      c3 = Condition.new
      c3.and :view_hide , 1
      c3.and "sql", "adminlibrary_roles.role_code = 'r'"
      c3.and "sql", "adminlibrary_roles.group_code = '#{parent_code}'"
    end

    sql = Condition.new
    sql.or c1
    sql.or c2
    sql.or c3 if parent_code

    join = "INNER JOIN adminlibrary_roles ON adminlibrary_controls.id = adminlibrary_roles.title_id"

    @admin_items = {}
  end



end
