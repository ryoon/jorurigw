class Gwfaq::Public::Piece::BannersController < ApplicationController
  include Gwboard::Controller::Authorize
  include Gwfaq::Model::DbnameAlias

  def index
    @title = Gwfaq::Control.find_by_id(params[:title_id])
    return http_error(404) unless @title

    get_writable_flag_only unless params[:piece_param].blank?
  end

end
