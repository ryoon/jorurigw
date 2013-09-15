class Gw::Public::ConfigSettingsController < ApplicationController
  include System::Controller::Scaffold
  include Gwboard::Model::DbnameAlias
  include Gwmonitor::Model::Database

  def initialize_scaffold

  end

  def init_params

    params[:limit] = nz(params[:limit],30)

    @admin_role = Gw.is_admin_admin?

    @editor_role  = Gw.is_editor?

    @role_tabs  = System::Model::Role.get(1, Site.user.id ,'edit_tab', 'editor')

    @role_users = System::Model::Role.get(1, Site.user.id ,'system_users','editor')

    @is_readable = nil
    params[:system]='gwbbs'
    admin_flags
    @role_bbs    =    @is_readable

    @is_readable = nil
    params[:system]='gwfaq'
    admin_flags
    @role_faq   = @is_readable

    @is_readable = nil
    params[:system]='gwqa'
    admin_flags
    @role_qa   = @is_readable

    @is_readable = nil
    params[:system]='doclibrary'
    admin_flags
    @role_doclibrary    = @is_readable

    @is_readable = nil
    params[:system]='digitallibrary'
    admin_flags
    @role_digitallibrary    = @is_readable

    @is_sysadm = nil
    @is_bbsadm = nil
    role_gwcircular('_menu')
    @role_gwcircular_sysadmin       = @is_sysadm
    @role_gwcircular_bbsadmin       = @is_bbsadm
    @role_gwcircular  = @role_gwcircular_sysadmin || @role_gwcircular_bbsadmin

    @is_sysadm = nil
    system_admin_flags
    @role_gwmonitor       = @is_sysadm


    @is_gw_config_settings_roles  = Gw.is_admin_or_editor?
    @u_role = @is_gw_config_settings_roles

    @portal_editor = @role_tabs

    @role_board = @role_bbs ||  @role_faq ||  @role_qa  ||  @role_doclibrary  ||  @role_digitallibrary  ||  @role_gwcircular  ||  @role_gwmonitor
    @role_board2 = @role_bbs ||  @role_faq ||  @role_qa  ||  @role_doclibrary  ||  @role_digitallibrary

    @base_editor   = @role_users

    if @admin_role==true
      params[:c1]  = nz(params[:c1],1)
      params[:c2]  = nz(params[:c2],1)
    else
      if @u_role==true
        params[:c1]  = nz(params[:c1],1)
        if @portal_editor == true
          params[:c2]  = nz(params[:c2],1)
        elsif @role_board2 == true
          params[:c2]  = nz(params[:c2],6)
        elsif @base_editor == true
          params[:c2]  = nz(params[:c2],5)
        else
          params[:c2]  = nz(params[:c2],1)
        end
      end
    end
    @css = %w(/layout/admin/style.css)

    qsa = ['c1' , 'c2']
    @qs = qsa.delete_if{|x| nz(params[x],'')==''}.collect{|x| %Q(#{x}=#{params[x]})}.join('&')
  end

  def index
    init_params
  end

  def ind_settings
    init_params
  end

  def role_gwcircular(title_id = '_menu')
    @is_sysadm = true if System::Model::Role.get(1, Site.user.id ,'gwcircular', 'admin')
    @is_sysadm = true if System::Model::Role.get(2, Site.user_group.id ,'gwcircular', 'admin') unless @is_sysadm
    @is_bbsadm = true if @is_sysadm

    unless @is_bbsadm
      item = Gwcircular::Adm.new
      item.and :user_id, 0
      item.and :group_code, Site.user_group.code
      item.and :title_id, title_id unless title_id == '_menu'
      items = item.find(:all)
      @is_bbsadm = true unless items.blank?

      unless @is_bbsadm
        item = Gwcircular::Adm.new
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

end
