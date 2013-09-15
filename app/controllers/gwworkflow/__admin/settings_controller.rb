# encoding:utf-8
class Gwworkflow::Admin::SettingsController < Gw::Controller::Admin::Base

  include Gwboard::Controller::Scaffold
  include Gwboard::Controller::Common
  include Gwworkflow::Model::DbnameAlias
  include Gwworkflow::Controller::Authorize
  layout "admin/template/gwworkflow"

  rescue_from ActionController::InvalidAuthenticityToken, :with => :invalidtoken

  def pre_dispatch
    params[:title_id] = 1
    @title = Gwworkflow::Control.find_by_id(params[:title_id])
    return http_error(404) unless @title
    Page.title = "回覧板 機能設定"
    @css = ["/_common/themes/gw/css/circular.css"]
    params[:limit] = @title.default_limit unless @title.default_limit.blank?
  end

  def index
    admin_flags(@title.id)
  end

  private
  def invalidtoken
    return http_error(404)
  end
end
