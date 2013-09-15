class Cms::Map < ActiveRecord::Base
  include System::Model::Base
  include System::Model::Tree
  include System::Model::Unid
  include System::Model::Unid::Creator
  include System::Model::Base::Content
  
  belongs_to :status,   :foreign_key => :state,      :class_name => 'System::Base::Status'
  belongs_to :parent,   :foreign_key => :parent_id,  :class_name => 'Cms::Route'
  belongs_to :node,     :foreign_key => :node_id,    :class_name => 'Cms::Node'
  has_many   :children, :foreign_key => :parent_id,  :class_name => 'Cms::Map',  :order => :sort_no
  
  validates_presence_of :sort_no, :node_id
  
  def states
    {'public' => '公開'}
  end
  
  def display_title
    return title if title.to_s != ''
    return node.title if node
    ''
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
  
end
