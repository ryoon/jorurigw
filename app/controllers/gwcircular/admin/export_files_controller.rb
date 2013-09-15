class Gwcircular::Admin::ExportFilesController < ApplicationController
  include System::Controller::Scaffold

  rescue_from ActionController::InvalidAuthenticityToken, :with => :invalidtoken

  def initialize_scaffold
    params[:title_id] = 1
    @title = Gwcircular::Control.find_by_id(params[:title_id])
    return http_error(404) unless @title
    @parent = Gwcircular::Doc.find_by_id(params[:parent_id])
    return http_error(404) unless @parent
  end

  def index
    target_zip_file ="#{RAILS_ROOT}/tmp/gwcircular/#{sprintf('%06d',@parent.id)}.zip"
    send_file target_zip_file if FileTest.exist?(target_zip_file)

    unless FileTest.exist?(target_zip_file)
      flash[:notice] = '出力対象の添付ファイルがありません。'
      redirect_to "/gwcircular/#{@parent.id}/file_exports"
    end
  end

private
  def invalidtoken

  end
end