class Pref::Public::SectionsController < ApplicationController
  include Pref::Controller::Feed
  
  def index
    item = Pref::Section.new.public
    item.in_department
    @items = item.find(:all, :order => "pref_sections.group_id + 0")
  end
  
  def show
    item = Pref::Section.new.public
    item.name = params[:name]
    return http_error(404) unless @item = item.find(:first)
    
    Site.current_item = @item
    Page.title        = @item.display_title
    
    unless group = System::Group.find(@item.group_id)
      return http_error(404)
    end
    
    if group.level_no == 2
      return show_department
    elsif group.level_no == 3
      return show_section
    end
    
    return http_error(404)
  end
  
  def show_department
    doc = Pref::Doc.new.public
    doc.visible_in_list
    doc.department_is @item
    doc.page 1, 10
    @docs = doc.find(:all, :order => 'published_at DESC')
    return true if render_feed @docs
    
    attr = Pref::Attribute.new.public
    @attributes = attr.find(:all, :order => :sort_no)
    
    @children_docs = Proc.new do |attr|
      doc = Pref::Doc.new.public
      doc.visible_in_list
      doc.department_is @item
      doc.attribute_is attr
      doc.page 1, 10
      @docs = doc.find(:all, :order => 'published_at DESC')
    end
    
    render :action => :show_department
  end
  
  def show_section
    doc = Pref::Doc.new.public
    doc.visible_in_list
    doc.section_is @item
    doc.page 1, 10
    @docs = doc.find(:all, :order => 'published_at DESC')
    return true if render_feed @docs
    
    attr = Pref::Attribute.new.public
    @attributes = attr.find(:all, :order => :sort_no)
    
    @children_docs = Proc.new do |attr|
      doc = Pref::Doc.new.public
      doc.visible_in_list
      doc.section_is @item
      doc.attribute_is attr
      doc.page 1, 10
      @docs = doc.find(:all, :order => 'published_at DESC')
    end
    
    render :action => :show_section
  end
end
