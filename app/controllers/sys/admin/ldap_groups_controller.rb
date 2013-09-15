# encoding: utf-8
class Sys::Admin::LdapGroupsController < Sys::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  layout  'admin/sys'

  def pre_dispatch
    return error_auth unless Core.user.has_auth?(:manager)
    return render(:text=> "LDAPサーバに接続できません。", :layout => true) unless Core.ldap.connection
    @admin      = System::User.is_admin?
    return authentication_error(403) unless @admin == true

    if params[:parent] == '0'
      @parent  = nil
      @parents = []
    else
      @parent  = Core.ldap.group.find(params[:parent])
      @parents = @parent.parents
    end
    Core.title = "JoruriGw admin LDAP情報管理"
  end
  
  def index
    if !@parent
      @groups = Core.ldap.group.children
      @users  = []
    else
      @groups = @parent.children
      @users  = @parent.users
    end
  end
end
