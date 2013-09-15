class Gwqa::Admin::DocsController < ApplicationController

  def index
    item = Gwqa::Control.new
    item.page   params[:page], params[:limit]
    item.order  params[:id], "updated_at DESC"
    @items = item.find(:all)
  end

end
