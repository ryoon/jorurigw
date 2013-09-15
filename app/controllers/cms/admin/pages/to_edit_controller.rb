class Cms::Admin::Pages::ToEditController < Cms::Admin::PagesController
  def index
    item = Cms::Page.new.editable
    item.node_id = @parent.id
    
    #join = "INNER JOIN system_creators USING(unid)"
    #item.and "system_creators.group_id", Site.user_group.id
    
    item.page  params[:page], params[:limit]
    item.order params[:sort], 'updated_at DESC'
    @items = item.find(:all)
    _index @items
  end
end
