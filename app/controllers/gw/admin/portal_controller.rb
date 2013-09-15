# encoding: utf-8
class Gw::Admin::PortalController < Gw::Controller::Admin::Base
  include System::Controller::Scaffold
  layout "admin/template/portal"

  def initialize_scaffold
    Page.title = "Joruri Gw ポータル"
  end

  def index
    session[:request_fullpath] = request.fullpath
  end
end
