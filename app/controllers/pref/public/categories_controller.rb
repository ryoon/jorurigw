class Pref::Public::CategoriesController < ApplicationController
  include Pref::Controller::Feed
  
  def index
    item = Pref::Category.new.public
    @items = item.find(:all, :conditions => {:parent_id => 0}, :order => :sort_no)
  end
  
  def show
    item = Pref::Category.new.public
    item.name = params[:name]
    
    if @item = item.find(:first)
      Site.current_item = @item
      Page.title        = @item.title
      
      if @item.level_no == 1
        return show_group
      elsif @item.level_no == 2
        return show_category
      end
    end
    
    return http_error(404)
  end
  
  def show_group
    @categories = @item.public_children
    
    doc = Pref::Doc.new.public
    doc.visible_in_list
    doc.category_in @categories
    doc.page 1, 10
    @docs = doc.find(:all, :order => 'published_at DESC')
    return true if render_feed @docs
    
    @children_docs = Proc.new do |cate|
      doc = Pref::Doc.new.public
      doc.visible_in_list
      doc.category_is cate
      doc.page 1, 10
      @docs = doc.find(:all, :order => 'published_at DESC')
    end
    
    render :action => :show_group
  end
  
  def show_category
    doc = Pref::Doc.new.public
    doc.visible_in_list
    doc.category_is @item
    doc.page 1, 10
    @docs = doc.find(:all, :order => 'published_at DESC')
    return true if render_feed @docs
    
    sec = Pref::Section.new.public
    sec.in_department
    @departments = sec.find(:all, :order => "pref_sections.id + 0")
    
    @children_docs = Proc.new do |dep|
      doc = Pref::Doc.new.public
      doc.visible_in_list
      doc.category_is @item
      doc.department_is dep
      doc.page 1, 10
      @docs = doc.find(:all, :order => 'published_at DESC')
    end
    
    render :action => :show_category
  end
end
