class Gw::Admin::PortalController < ApplicationController
  include System::Controller::Scaffold

  def index
    item = Gw::PortalUserSetting.new
    @items = item.find(:all, :order => 'idx')
    _index @items
  end

end
