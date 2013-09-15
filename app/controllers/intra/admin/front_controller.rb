class Intra::Admin::FrontController < ApplicationController
  def index
    return redirect_to('/') unless Gw.is_admin_admin?
    item = Intra::Message.new.public
    @messages = item.find(:all, :order => 'published_at DESC')
    item = Intra::Maintenance.new.public
    @maintenances = item.find(:all, :order => 'published_at DESC')
    @calendar = Util::Date::Calendar.new(nil, nil)
    @css = ['/_common/themes/admin/intra.css']
  end
end
