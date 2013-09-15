class Pref::Admin::Docs::ToEditController < Pref::Admin::DocsController
  def index
    item = Pref::Doc.new.editable
    item.content_id = @content.id
    item.page  params[:page], params[:limit]
    item.order params[:sort], 'updated_at DESC'
    @items = item.find(:all)
    _index @items
  end
end
