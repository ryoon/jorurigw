class Gw::Public::MobileSettingsController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
  end

  def index
    init_params
    @user = System::User.find_by_code(Site.user.code)
    return http_error(404) if @user.blank?
  end

  def access_edit
    init_params
    @user = System::User.find_by_code(Site.user.code)
    return http_error(404) if @user.blank?
  end

  def access_updates
    init_params
    @user = System::User.find_by_code(Site.user.code)
    return http_error(404) if @user.blank?

    @user.mobile_access = params[:user]['mobile_access'].to_i
    @user.save(false)

    u_cond = "account='#{Site.user.code}'"
    u_order = "account"
    @mail_user  = Sys::User.find(:first , :conditions=>u_cond , :order=>u_order )
    if @mail_user.blank?
    else
      @mail_user.mobile_access = params[:user]['mobile_access'].to_i
      @mail_user.save(false)
    end
    location = "#{Gw.chop_with(Site.current_node.public_uri,'/')}?#{@qs}"
    flash[:notice] = "携帯アクセス許可設定を更新しました。"
    return redirect_to location
  end

  def password_edit
    init_params
    @user = System::User.find_by_code(Site.user.code)
    return http_error(404) if @user.blank?
  end

  def password_updates
    init_params

    @user = System::User.find_by_code(Site.user.code)
    return http_error(404) if @user.blank?

    @user.mobile_password = params[:user]['mobile_password'].to_s
    ret = @user.mobile_pass_check

    if ret == true
      @user.save(false)
      # mail sys_users update
      u_cond = "account='#{Site.user.code}'"
      u_order = "account"
      @mail_user  = Sys::User.find(:first , :conditions=>u_cond , :order=>u_order )
      if @mail_user.blank?
      else
        @mail_user.mobile_password = params[:user]['mobile_password'].to_s
        @mail_user.save(false)
      end
      location = "#{Gw.chop_with(Site.current_node.public_uri,'/')}?#{@qs}"
      flash[:notice] = "携帯アクセスパスワードを更新しました。"
      return redirect_to location
    else
      respond_to do |format|
        format.html { render :action => :password_edit }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  def init_params
    search_condition
    setting_sortkeys

    @css = %w(/_common/themes/gw/css/gw.css)
  end

  def search_condition
    qsa = ['c1' , 'c2']
    @qs = qsa.delete_if{|x| nz(params[x],'')==''}.collect{|x| %Q(#{x}=#{params[x]})}.join('&')
  end

  def setting_sortkeys
    @sort_keys = nz(params[:sort_keys], 'id')
  end

end
