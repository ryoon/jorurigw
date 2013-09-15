class Gwcircular::Public::SettingsController < ApplicationController

  include Gwboard::Controller::Scaffold
  include Gwboard::Controller::Common
  include Gwcircular::Model::DbnameAlias
  include Gwcircular::Controller::Authorize

  rescue_from ActionController::InvalidAuthenticityToken, :with => :invalidtoken

  def initialize_scaffold
    params[:title_id] = 1
    @title = Gwcircular::Control.find_by_id(params[:title_id])
    return http_error(404) unless @title
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
