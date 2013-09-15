class Gwmonitor::Public::SettingsController < ApplicationController

  include System::Controller::Scaffold
  include Gwmonitor::Controller::Systemname

  rescue_from ActionController::InvalidAuthenticityToken, :with => :invalidtoken

  def initialize_scaffold
    @system_title = disp_system_name
    @css = ["/_common/themes/gw/css/monitor.css"]
  end

  def index
  end

  private
  def invalidtoken
    return http_error(404)
  end
end
