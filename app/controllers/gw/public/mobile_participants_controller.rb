class Gw::Public::MobileParticipantsController < ApplicationController
  include System::Controller::Scaffold
  include Gw::Controller::Mobile::Participant

  def initialize_scaffold
    return redirect_to(request.env['PATH_INFO']) if params[:reset]
  end

  def index
    if params[:group_id].blank? or params[:group_id].to_i == 0
      @group_id = 0
      @items = ""
      @group = ""
    else
      @group_id = params[:group_id].to_i
      @items = System::User.get_user_select(params[:group_id],nil,{:ldap => 1})
      @group = System::Group.find_by_id(params[:group_id])
    end
  end

end
