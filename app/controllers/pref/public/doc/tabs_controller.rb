class Pref::Public::Doc::TabsController < ApplicationController
  def index
    @skip_layout = true

    @items = {}

    doc = Pref::Doc.new.public
    doc.visible_in_recent
    doc.page 1, 10
    @items['shinchaku'] = doc.find(:all, :order => 'published_at DESC')

    doc = Pref::Doc.new.public
    doc.visible_in_notice
    doc.page 1, 10
    @items['chuumoku'] = doc.find(:all, :order => 'published_at DESC')

    doc = Pref::Doc.new.public
    doc.visible_in_list

    cond = '1=1'
    if attr = Pref::Attribute.find_by_name('event')
      cond = "attribute_id = #{attr.id}"
    end

    tmp = []
    Pref::Category.find_by_name('kankoubussan').public_children.each{|c| tmp << c.id}
    cond << " OR category_ids REGEXP '(^| )(#{tmp.join('|')})( |$)'"
    cond = "( #{cond} )"

    doc.page 1, 10
    @items['kankou'] = doc.find(:all, :conditions => cond, :order => 'published_at DESC')

    cond = "name = 'saiyou' OR name = 'bosyuu'"
    if attr = Pref::Attribute.find(:all, :conditions => cond)
      doc = Pref::Doc.new.public
      doc.visible_in_list
      doc.attribute_in attr
      doc.page 1, 10
      @items['bosyuu'] = doc.find(:all, :order => 'published_at DESC')
    end

    if attr = Pref::Attribute.find_by_name('nyuusatsu')
      doc = Pref::Doc.new.public
      doc.visible_in_list
      doc.attribute_is attr
      doc.page 1, 10
      @items['nyuusatsu'] = doc.find(:all, :order => 'published_at DESC')
    end

    if cate = Pref::Category.find_by_name('bousai')
      doc = Pref::Doc.new.public
      doc.visible_in_list
      doc.category_in cate.public_children
      doc.page 1, 10
      @items['bousai'] = doc.find(:all, :order => 'published_at DESC')
    end
  end
end
