class Gwmonitor::Public::HelpConfigsController < ApplicationController

  include System::Controller::Scaffold
  include Gwmonitor::Model::Database
  include Gwmonitor::Controller::Systemname

  def initialize_scaffold
    @system_title = "#{disp_system_name}ヘルプリンク設定"
    @css = ["/_common/themes/gw/css/monitor.css"]
  end

  def index
    system_admin_flags
    return authentication_error(403) unless @is_sysadm

    item = Gw::UserProperty.new
    item.and :class_id, 3
    item.and :name, 'gwmonitor'
    item.and :type_name, 'help_link'
    @item = item.find(:first)
    return http_error(404) unless @item
    @array_help = Array.new(2, ['', ''])
    @array_help = JsonParser.new.parse(@item.options) unless @item.blank?
  end

  #
  def update
    @item = Gw::UserProperty.find_by_id(params[:id])
    return http_error(404) unless @item
    help_0 = "[" + '"' + params[:help_0].to_s + '"' + "]"
    help_1 = "[" + '"' + params[:help_1].to_s + '"' + "]"
    @item.options = "[" + "#{help_0}, #{help_1}" + "]"
    @item.save
    redirect_to '/gwmonitor/settings'
  end

end
