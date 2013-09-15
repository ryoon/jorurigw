class Cms::Route < ActiveRecord::Base
  include System::Model::Base
  include System::Model::Tree
  include System::Model::Unid
  include System::Model::Unid::Creator
  include Cms::Model::Base::Content
  
  belongs_to :status,  :foreign_key => :state,      :class_name => 'System::Base::Status'
  belongs_to :parent,  :foreign_key => :parent_id,  :class_name => 'Cms::Route'
  belongs_to :node,    :foreign_key => :node_id,    :class_name => 'Cms::Node'
  
  validates_presence_of :sort_no, :node_id
  
  def states
    {'public' => '公開'}
  end
  
  def display_title
    return title if title.to_s != ''
    node.title
  end
  
  def route_title
    display_title
  end
end
