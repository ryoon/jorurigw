class Gwworkflow::Admin::AjaxgroupsController < ApplicationController
  include System::Controller::Scaffold

  def getajax
    gid = ''
    gid = params[:s_genre] unless params[:s_genre].blank?
    if gid.blank?
      @item = []
    else
      @item = Gwworkflow::CustomGroup.get_user_select_ajax(gid)
    end
    _show @item
  end

end