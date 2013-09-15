class Cms::Node < ActiveRecord::Base
  include System::Model::Base
  include System::Model::Tree
  include System::Model::Unid
  include System::Model::Unid::Creator
  include System::Model::Base::Content
  
  belongs_to :status,   :foreign_key => :state,      :class_name => 'System::Base::Status'
  belongs_to :content,  :foreign_key => :content_id, :class_name => 'Cms::Content'
  belongs_to :layout,   :foreign_key => :layout_id,  :class_name => 'Cms::Layout'
  has_many   :children, :foreign_key => :parent_id,  :class_name => 'Cms::Node',  :order => :name
  has_many   :pages,    :foreign_key => :node_id,    :class_name => 'Cms::Page',  :dependent => :destroy
  has_many   :routes,   :foreign_key => :node_id,    :class_name => 'Cms::Route', :dependent => :destroy
  has_many   :maps,     :foreign_key => :node_id,    :class_name => 'Cms::Map',   :dependent => :destroy
  
  validates_presence_of :state, :controller, :name, :title
  
  def states
    {'public' => '公開'}
  end
  
  def module
    content ? content.module : 'cms'
  end
  
  def all_nodes_with_level
    search = lambda do |current, level|
      _nodes = {:level => level, :item => current, :children => nil}
      return _nodes if level >= 10
      return _nodes if current.children.size == 0
      
      _tmp = []
      current.children.each do |child|
        next unless _c = search.call(child, level + 1)
        _tmp << _c
      end
      _nodes[:children] = _tmp
      return _nodes
    end
    
    search.call(self, 0)
  end
  
  def all_nodes_collection(options = {})
    collection = lambda do |current, level|
      title = ''
      if level > 0
        (level - 1).times {|i| title += options[:indent] || '  '}
        title += options[:child] || '  ' if level > 0
      end
      title += current[:item].title
      list = [[title, current[:item].id]]
      return list unless current[:children]
      
      current[:children].each do |child|
        list += collection.call(child, level + 1)
      end
      return list
    end
    
    collection.call(all_nodes_with_level, 0)
  end
  
  def public_uri
    uri = Site.uri
    parent_tree.each do |node|
      uri += node.name + '/' if node.name != '/'
    end
    uri
  end
  
  def css_id
    '' 
  end
  
  def css_class
    return 'content content' + self.controller.singularize.camelize
  end
end