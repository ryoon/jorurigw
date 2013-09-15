class Gw::Public::MobileParticipantsController < ApplicationController
  include System::Controller::Scaffold
  include Gw::Controller::Mobile::Participant

  def initialize_scaffold
    return redirect_to(request.env['PATH_INFO']) if params[:reset]
  end

  def index
    if params[:group_id].blank? or params[:group_id].to_i == 0
      @group_id = Site.user_group.id
      @group = Site.user_group
    else
      @group_id = params[:group_id].to_i
      @group = System::Group.find_by_id(params[:group_id])
    end
    @items = System::User.get_user_select(@group_id,nil)
    @groups  = System::Group.find(:all,
      :conditions=>["parent_id = ? AND state = ?",@group.id,"enabled"],:order=>:sort_no)
  end

end
