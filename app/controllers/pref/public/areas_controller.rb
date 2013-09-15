class Pref::Public::AreasController < ApplicationController
  include Pref::Controller::Feed
  
  def index
    item = Pref::Area.find(1)
    @items = item.public_children
  end
  
  def show
    item = Pref::Area.new.public
    item.name = params[:name]
    
    if @item = item.find(:first)
      Site.current_item = @item
      Page.title        = @item.title
      
      if @item.level_no == 2
        return show_area
      elsif @item.level_no == 3
        return show_city
      end
    end
    
    return http_error(404)
  end
  
  def show_area
    doc = Pref::Doc.new.public
    doc.visible_in_list
    doc.area_is @item
    doc.page 1, 10
    @docs = doc.find(:all, :order => 'published_at DESC')
    return true if render_feed @docs
    
    @cities = @item.public_children
    
    @children_docs = Proc.new do |city|
      doc = Pref::Doc.new.public
      doc.visible_in_list
      doc.area_is city
      doc.page 1, 10
      @docs = doc.find(:all, :order => 'published_at DESC')
    end
    
    render :action => :show_area
  end
  
  def show_city
    doc = Pref::Doc.new.public
    doc.visible_in_list
    doc.area_is @item
    doc.page 1, 10
    @docs = doc.find(:all, :order => 'published_at DESC')
    return true if render_feed @docs
    
    attr = Pref::Attribute.new.public
    @attributes = attr.find(:all, :order => :sort_no)
    
    @children_docs = Proc.new do |attr|
      doc = Pref::Doc.new.public
      doc.visible_in_list
      doc.area_is @item
      doc.attribute_is attr
      doc.page 1, 10
      @docs = doc.find(:all, :order => 'published_at DESC')
    end
    
    render :action => :show_city
  end
end
