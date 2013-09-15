class System::Admin::AccountController < ApplicationController
  protect_from_forgery :except => :login

  def login
    login_common :admin
  end

  def logout
    logout_common :admin
  end

  def info
    self.class.layout 'empty'

    respond_to do |format|
      format.html { render }
      format.xml  { render :xml => Site.user.to_xml(:root => 'item', :include => :groups) }
    end
  end

private
  def login_common(mode)
    _cond = "class_id=3 and name='pref_only_assembly' and type_name='account' "
    _order = "class_id desc"
    only_pref_account   = Gw::UserProperty.find(:first , :conditions=>_cond ,:order=>_order)
    if only_pref_account.blank?
      only_assembly_user_account = '502'
    else
      only_assembly_user_account = only_pref_account.options
    end

    self.class.layout 'empty'
    admin_uri = mode == :admin ? '/_admin' : '/'

    if request.parameters['url'] =~ /\/api\/pref/
      xml = api_pref_exectives(request)
      respond_to do |format|
        format.xml { render :text => xml ,:layout=>false }
      end
      return true
    end

    if request.parameters['url'] =~ /\/api\/checker/
      state,xml = api_checker(request)
      respond_to do |format|
        format.xml { render :text => xml ,:layout=>false ,:state=>state }
      end
      return true
    end

    if request.parameters['url'] =~ /\/api\/checker_login/
      xml= nil
      state = 200
      respond_to do |format|
        format.xml { render :text => xml ,:layout=>false ,:state=>state }
      end
      return true
    end

    if request.parameters['url'] =~ /\/api\/air_sso/
      xml= nil
      state = 200
      respond_to do |format|
        format.xml { render :text => xml ,:layout=>false ,:state=>state }
      end
      return true
    end

    if params[:account].to_s == only_assembly_user_account.to_s
      if params[:url]=~ /\/gw\/pref_only_/
        admin_uri = params[:url]
      else
        admin_uri = '/gw/pref_only_assembly'
      end
    end

    return redirect_to(admin_uri) if logged_in?
    return unless request.post?

    if params[:password].to_s == 'p'+params[:account].to_s
      flash[:notice] = "初期パスワードではログインできません。パスワードを変更してください。" if flash[:notice].nil?
      respond_to do |format|
        format.html { render }
        format.xml  { render(:xml => '<errors />') }
      end
      return true
    end

    if request.mobile?
      unless new_login_mobile(params[:account], params[:password], params[:mobile_password])
        flash[:notice] = "ID・パスワードを正しく入力してください" if flash[:notice].nil?
        respond_to do |format|
          format.html { render }
          format.xml  { render(:xml => '<errors />') }
        end
        return true
      end
    else
      unless new_login(params[:account], params[:password])
        flash[:notice] = "ID・パスワードを正しく入力してください" if flash[:notice].nil?
        respond_to do |format|
          format.html { render }
          format.xml  { render(:xml => '<errors />') }
        end
        return true
      end
    end

    if params[:remember_me] == "1"
      self.current_user.remember_me
      cookies[:auth_token] = {
        :value   => self.current_user.remember_token,
        :expires => self.current_user.remember_token_expires_at
      }
    end

    if params[:account].to_s == only_assembly_user_account.to_s
      respond_to do |format|
        uri = admin_uri
        format.html { redirect_to(uri) }
        format.xml  { render(:xml => current_user.to_xml) }
      end
      return true
    end

    respond_to do |format|
      uri = params[:url].to_s == '' ? admin_uri : params[:url]
      format.html { redirect_to(uri) }
      format.xml  { render(:xml => current_user.to_xml) }
    end


    user = System::User.find(:first, :conditions => ['id = ?', session[:user_id]])
    System::LoginLog.put_log(user)

  end

  def logout_common(mode)
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session

    if mode == :admin
      redirect_to('action' => 'login')
    else
      redirect_to '/'
    end
  end

  def api_pref_exectives(request)
    xml = nil

    if request.parameters['url'] =~ /\/api\/pref\/exectives/
      dump ['api_pref_exectives',Time.now.strftime('%Y-%m-%d %H:%M:%S'),request.parameters['url']]
      Gw::Tool::PrefExective.accesslog_save(request.remote_ip)
      ret = Gw::Tool::PrefExective.member_xml_output
      dump ['api_pref_exectives_ret',Time.now.strftime('%Y-%m-%d %H:%M:%S'),ret]
      xml = ret
    elsif request.parameters['url'] =~ /\/api\/pref\/executives/
      dump ['api_pref_leaders',Time.now.strftime('%Y-%m-%d %H:%M:%S'),request.parameters['url']]
      if request.parameters['url'] =~ /kind=2/
        ret = Gw::Tool::PrefExective.leader_xml_output( 2 )
      else
        ret = Gw::Tool::PrefExective.leader_xml_output
      end
      dump ['api_pref_leaders_ret',Time.now.strftime('%Y-%m-%d %H:%M:%S'),ret]
      xml = ret
    elsif request.parameters['url'] =~ /\/api\/pref\/secretary/
      dump ['api_pref_secretary',Time.now.strftime('%Y-%m-%d %H:%M:%S'),request.parameters['url']]
      if request.parameters['url'] =~ /kind=2/
    ret = Gw::Tool::PrefExective.secretary_xml_output( 2 )
      else
    ret = Gw::Tool::PrefExective.secretary_xml_output
      end
      dump ['api_pref_secretary_ret',Time.now.strftime('%Y-%m-%d %H:%M:%S'),ret]
      xml = ret
    elsif request.parameters['url'] =~ /\/api\/pref\/access/
      dump ['api_pref_access',Time.now.strftime('%Y-%m-%d %H:%M:%S'),request.parameters['url']]
      if request.parameters['url'] =~ /state=on/
        state = "on"
      else
        state = "off"
      end
      id_arr = request.parameters['url'].split("uid=")
      if request.parameters['url'] =~ /kind=2/
        ret = Gw::Tool::PrefExective.exective_access(state, id_arr[1])
      else
        ret = Gw::Tool::PrefExective.assembly_access(state, id_arr[1])
      end
      dump ['api_pref_access',Time.now.strftime('%Y-%m-%d %H:%M:%S'),ret]
      xml = ret
    elsif request.parameters['url'] =~ /\/api\/pref\/monitors/
      dump ['api_pref_monitors',Time.now.strftime('%Y-%m-%d %H:%M:%S'),request.parameters['url']]
      if request.parameters['url'] =~ /type=1/
        type = 1
      else
        type = 2
      end
      dump ['api_pref_monitors',Time.now.strftime('%Y-%m-%d %H:%M:%S'),ret]
      xml = ret
    end
    return xml
  end

  def api_checker(request)
    dump ['api_checker_login_common',Time.now.strftime('%Y-%m-%d %H:%M:%S'),request.parameters['url']]
    unless logged_in?
      unless new_login(params[:account], params[:password])
        xml = %Q(<errors>ID・パスワードを正しく入力してください</erros>)
        return 201,xml
      end
    end
    u_cond  = "state='enabled' and code='#{params[:account]}'"
    u_order = "code"
    user  = System::User.find(:first , :conditions=>u_cond , :order=>u_order)
    if user.blank?
      return 201,nil
    end
    uid   = user.id
    ucode = params[:account]
    xml = nil
      dump ['api_checker_login_common',Time.now.strftime('%Y-%m-%d %H:%M:%S'),request.parameters['url']]
      ret = Gw::Tool::Riminder.checker_api(uid)
      dump ['api_checker_login_common_ret',Time.now.strftime('%Y-%m-%d %H:%M:%S'),ret]
      xml = ret[:xml]
    return 200,xml
  end

end
