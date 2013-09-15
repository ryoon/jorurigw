class Cms::Public::NodesController < ApplicationController
  def index
    name = params[:name] ? "#{params[:name]}.#{params[:format]}" : 'index.html'

    item = Cms::Page.new.public
    item.node_id = Site.current_node.id
    item.name    = name

    return http_error(404) unless @item = item.find(:first)
    Site.current_item = @item
    Page.title        = @item.title
  end
end
