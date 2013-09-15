class Cms::Public::Piece::BreadCrumbsController < ApplicationController
  def index
    @crumbs = []

    routes = Site.current_node.routes.sort_by{|r| r.parent.sort_no}
    routes.each do |r|
      @crumbs << r.parent_tree
    end

    if Site.current_item.class != Cms::Node
      @crumbs = Site.current_item.bread_crumbs(@crumbs, :uri => Site.current_node.public_uri)
    end

    @render_crumbs = lambda do |crumbs|
      h = ''
      crumbs.each do |c|
        h << '<div>'
        c.each_with_index do |c2, i2|
          h << ' &gt; ' if i2 != 0
          if c2.class == Cms::Route
            h << '<a href="' + c2.node.public_uri + '">' + c2.display_title + '</a>'
          elsif c2.class == Array
            c2.each_with_index do |c3, i3|
              h << '、' if i3 != 0
              h << '<a href="' + c3[:uri] + '">' + c3[:name] + '</a>'
            end
          else
            h << '<a href="' + c2[:uri] + '">' + c2[:name] + '</a>'
          end
        end
        h << '</div>'
      end
      h
    end
  end
end
