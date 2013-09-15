class Pref::Public::AttributesController < ApplicationController
  include Pref::Controller::Feed
  
  def index
    item = Pref::Attribute.new.public
    @items = item.find(:all, :order => :sort_no)
  end
  
  def show
    item = Pref::Attribute.new.public
    item.name = params[:name]
    
    unless @item = item.find(:first)
      return http_error(404)
    end
    
    Site.current_item = @item
    Page.title        = @item.title
    
    doc = Pref::Doc.new.public
    doc.visible_in_list
    doc.attribute_is @item
    doc.page 1, 10
    @docs = doc.find(:all, :order => 'published_at DESC')
    return true if render_feed @docs
    
    sec = Pref::Section.new.public
    sec.in_department
    @departments = sec.find(:all, :order => "pref_sections.id + 0")
    
    @children_docs = Proc.new do |dep|
      doc = Pref::Doc.new.public
      doc.visible_in_list
      doc.attribute_is @item
      doc.department_is dep
      doc.page 1, 10
      @docs = doc.find(:all, :order => 'published_at DESC')
    end
  end
end
