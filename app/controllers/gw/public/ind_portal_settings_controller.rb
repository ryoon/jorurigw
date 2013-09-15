class Gw::Public::IndPortalSettingsController < ApplicationController
  include System::Controller::Scaffold

  def index
    return authentication_error(403) unless Gw::IndPortalSetting.valid_user?(Site.user.id)
    @item = Gw::IndPortalSetting.read
    _index @item
  end

  def update
    return authentication_error(403) unless Gw::IndPortalSetting.valid_user?(Site.user.id)
    @item = Gw::IndPortalSetting.read
    @item.attributes = params[:item]
    _update @item, :success_redirect_uri => "#{Site.current_node.public_uri}"
  end
end