class Cms::Admin::Pages::ToPublishController < Cms::Admin::PagesController
  def index
    item = Cms::Page.new.publishable
    item.node_id = @parent.id
    item.page  params[:page], params[:limit]
    item.order params[:sort], 'updated_at DESC'
    @items = item.find(:all)
    _index @items
  end
end
