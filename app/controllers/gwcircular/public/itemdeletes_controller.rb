class Gwcircular::Public::ItemdeletesController < ApplicationController

  include Gwboard::Controller::Scaffold
  include Gwboard::Controller::Common
  include Gwcircular::Model::DbnameAlias
  include Gwcircular::Controller::Authorize

  def initialize_scaffold
    @css = ["/_common/themes/gw/css/circular.css"]
  end

  def index
    check_gw_system_admin
    return authentication_error(403) unless @is_sysadm

    item = Gwcircular::Itemdelete.new
    item.and :content_id, 0
    @item = item.find(:first)
  end

  def edit
    item = Gwcircular::Itemdelete.new
    item.and :content_id, 0
    @item = item.find(:first)
    return unless @item.blank?

    @item = Gwcircular::Itemdelete.create({
      :content_id => 0 ,
      :admin_code => Site.user.code ,
      :limit_date => '1.month'
    })

  end

  def update
    item = Gwcircular::Itemdelete.new
    item.and :content_id, 0
    @item = item.find(:first)
    return if @item.blank?
    @item.attributes = params[:item]
    location = '/gw/admin_settings'
    _update(@item, :success_redirect_uri=>location)
  end

  def check_gw_system_admin
    @is_sysadm = true if System::Model::Role.get(1, Site.user.id ,'_admin', 'admin')
    @is_sysadm = true if System::Model::Role.get(2, Site.user_group.id ,'_admin', 'admin') unless @is_sysadm
    @is_bbsadm = true if @is_sysadm
  end

end
