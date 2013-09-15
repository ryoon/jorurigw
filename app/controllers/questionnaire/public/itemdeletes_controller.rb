# グループウエア掲示板　記事削除
#
###############################################################################

class Questionnaire::Public::ItemdeletesController < ApplicationController

  include System::Controller::Scaffold
  include Questionnaire::Model::Database

  def initialize_scaffold
    @system_title = "アンケート集計システム "
    @css = ["/_common/themes/gw/css/circular.css"]
  end

  def index
    check_gw_system_admin
    return authentication_error(403) unless @is_sysadm
 
    item = Questionnaire::Itemdelete.new
    item.and :content_id, 0
    @item = item.find(:first)
  end

  def edit
    check_gw_system_admin
    return authentication_error(403) unless @is_sysadm
    item = Questionnaire::Itemdelete.new
    item.and :content_id, 0
    @item = item.find(:first)
    return unless @item.blank?

    @item = Questionnaire::Itemdelete.create({
      :content_id => 0 ,
      :limit_date => '1.month'
    })
  
  end

  def update
    check_gw_system_admin
    return authentication_error(403) unless @is_sysadm
    item = Questionnaire::Itemdelete.new
    item.and :content_id, 0
    @item = item.find(:first)
    return if @item.blank?
    @item.admin_code = Site.user.code

    @item.attributes = params[:item]
    location = '/gw/config_settings?c1=1&c2=7'
    _update(@item, :success_redirect_uri=>location)
  end

  def check_gw_system_admin
    @is_gw_admin = Gw.is_admin_admin?
    @is_sysadm = true if @is_gw_admin == true
    @is_sysadm = true if System::Model::Role.get(1, Site.user.id ,'enquete', 'admin') unless @is_sysadm
    @is_sysadm = true if System::Model::Role.get(2, Site.user_group.id ,'enquete', 'admin') unless @is_sysadm
    @is_bbsadm = true if @is_sysadm
  end

end
