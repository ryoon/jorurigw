class Pref::Admin::Docs::ToPublishController < Pref::Admin::DocsController
  def index
    item = Pref::Doc.new.publishable
    item.content_id = @content.id
    item.page  params[:page], params[:limit]
    item.order params[:sort], 'updated_at DESC'
    @items = item.find(:all)
    _index @items
  end
end
