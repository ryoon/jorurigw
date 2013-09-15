class Attaches::Admin::GwfaqController < ApplicationController
  include System::Controller::Scaffold
  include Gwboard::Model::DbnameAlias

  def initialize_scaffold

    params[:system] = 'gwfaq'

    item = gwboard_control
    @title = item.find_by_id(params[:title_id])
    return http_error(404) unless @title
  end

  def download
    params[:id] = "#{params[:u_code].to_s}#{params[:d_code].to_s}"
    return http_error(404) if params[:id].blank?

    item = gwboard_file
    item = item.find_by_id(params[:id])
    return http_error(404) unless item
    return http_error(404) unless params[:name] == sprintf('%08d',Util::CheckDigit.check(item.parent_id))

    admin_flags
    get_readable_flag unless @is_readable
    return authentication_error(403) unless @is_readable

    chk = request.headers['HTTP_USER_AGENT']
    chk = chk.index("MSIE")
    if chk.blank?
      item_filename = item.filename
    else
      item_filename = item.filename.tosjis
    end

    begin
    f = open(item.f_name)
    if item.is_image
      send_data(f.read, :filename => item_filename, :type => item.content_type, :disposition=>'inline')
    else
      send_data(f.read, :filename => item_filename, :type => item.content_type)
    end
    f.close
    rescue
      dump "ダウンロードファイルなし:#{item_filename}"
      return http_error(404)
    end

    gwboard_file_close
  end

end
