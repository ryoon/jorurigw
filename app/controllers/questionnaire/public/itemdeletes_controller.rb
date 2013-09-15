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

  #
  #-主なアクションの記述 START index,show,new,edit,update, destroy---------------
  def index
    check_gw_system_admin
    return authentication_error(403) unless @is_sysadm  #GW管理者で無ければ403
 
    item = Questionnaire::Itemdelete.new
    item.and :content_id, 0
    @item = item.find(:first)
  end

  #cron用の削除設定
  #必ず1レコードになるようにする
  def edit
    item = Questionnaire::Itemdelete.new
    item.and :content_id, 0
    @item = item.find(:first)
    return unless @item.blank?

    @item = Questionnaire::Itemdelete.create({
      :content_id => 0 ,
      :admin_code => Site.user.code ,
      :limit_date => '1.month'
    })
  
  end

  #
  def update
    item = Questionnaire::Itemdelete.new
    item.and :content_id, 0
    @item = item.find(:first)
    return if @item.blank?
    @item.attributes = params[:item]
    location = '/gw/admin_settings'
    _update(@item, :success_redirect_uri=>location)
  end

  #-主なアクションの記述 END index ---------------------------------------------------
  #GW管理画面の管理者かチェックする
  def check_gw_system_admin
    #システムで登録されている管理者(システム管理者)ならtrueを返す
    @is_sysadm = true if System::Model::Role.get(1, Site.user.id ,'enquete', 'admin')
    #自分の所属idがシステムで登録されている管理者(システム管理者)ならtrueを返す
    @is_sysadm = true if System::Model::Role.get(2, Site.user_group.id ,'enquete', 'admin') unless @is_sysadm
    #システム管理者なら掲示板管理者の資格も持つ
    @is_bbsadm = true if @is_sysadm
  end

end
