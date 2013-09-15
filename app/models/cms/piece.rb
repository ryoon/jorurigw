class Cms::Piece < ActiveRecord::Base
  include System::Model::Base
  include System::Model::Unid
  include System::Model::Unid::Creator
  include System::Model::Unid::Recognition
  include System::Model::Unid::Publication
  include System::Model::Unid::Commitment
  include System::Model::Base::Content

  belongs_to :status,   :foreign_key => :state,      :class_name => 'System::Base::Status'
  belongs_to :content,  :foreign_key => :content_id, :class_name => 'Cms::Content'
  
  validates_presence_of :state, :name
  
  def module
    content ? content.module : 'cms'
  end
  
  def css_id
    name.gsub(/-/, '_').camelize(:lower)
  end
  
  def css_attributes
    attr = ''
    
    attr += ' id="' + css_id + '"' if css_id != ''
    
    _cls = 'piece'
    attr += ' class="' + _cls + '"' if _cls != ''
    
    attr
  end
end
