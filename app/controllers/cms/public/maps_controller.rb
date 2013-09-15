class Cms::Public::MapsController < ApplicationController
  def index
    name = params[:name] ? params[:name] + '.' + params[:format] : 'index.html'
    
    return http_error(404) if name != 'index.html'
    
    return http_error(404) unless root_map = Site.root_node.maps[0]
    
    options = {:indent => '　　', :child => '└'}
    
    collection = lambda do |current, level|
      indent = ''
      (level - 1).times {|i| indent += options[:indent]}
      
      child = (level > 0) ? options[:child] : '' 
      
      list = [{
        :indent => indent,
        :child  => child,
        :title  => current[:item].display_title,
        :uri    => current[:item].node ? current[:item].node.public_uri : nil,
      }]
      return list unless current[:children]
      
      current[:children].each do |child|
        list += collection.call(child, level + 1)
      end
      return list
    end
    
    @maps = collection.call(root_map.all_nodes_with_level, 0)
  end
end
