class Gwbbs::Public::SynthesetupController < ApplicationController
  include Gwboard::Controller::Scaffold

  def initialize_scaffold
    @css = ["/_common/themes/gw/css/bbs.css"]
  end

  def index
    check_gw_system_admin
    return authentication_error(403) unless @is_sysadm

  end

  def new
    check_gw_system_admin
    return authentication_error(403) unless @is_sysadm

    item = Gwboard::Synthesetup.new
    item.and :content_id, 0
    item = item.find(:first)
    check_gwbbs = false
    check_gwfaq = false
    check_gwqa = false
    check_doclib = false
    check_digitallib = false
    unless item.blank?
      check_gwbbs = item.gwbbs_check
      check_gwfaq = item.gwfaq_check
      check_gwqa = item.gwqa_check
      check_doclib = item.doclib_check
      check_digitallib = item.digitallib_check
    end

    @item = Gwboard::Synthesetup.new({
      :content_id => 0 ,
      :gwbbs_check => check_gwbbs ,
      :gwfaq_check => check_gwfaq ,
      :gwqa_check => check_gwqa ,
      :doclib_check => check_doclib ,
      :digitallib_check => check_digitallib
    })

end

  def create
    check_gw_system_admin
    return authentication_error(403) unless @is_sysadm

    Gwboard::Synthesetup.delete_all(["content_id = 0"])
    @item = Gwboard::Synthesetup.new(params[:item])
    @item.content_id = 0
    _create @item
  end

  def edit
    check_gw_system_admin
    return authentication_error(403) unless @is_sysadm

    item = Gwboard::Synthesetup.new
    item.and :content_id, 2
    @item = item.find(:first)

    if @item.blank?
      @item = Gwboard::Synthesetup.create({
        :content_id => 2 ,
        :limit_date => 'yesterday'
      })
    end

  end

  def update
    check_gw_system_admin
    return authentication_error(403) unless @is_sysadm

    @item = Gwboard::Synthesetup.find(params[:id])
    @item.attributes = params[:item]
    _update @item
  end

  def check_gw_system_admin
    @is_sysadm = true if System::Model::Role.get(1, Site.user.id ,'_admin', 'admin')
    @is_sysadm = true if System::Model::Role.get(2, Site.user_group.id ,'_admin', 'admin') unless @is_sysadm
    @is_bbsadm = true if @is_sysadm
  end

end