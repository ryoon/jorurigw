class Cms::PieceLink < ActiveRecord::Base
  include System::Model::Base
  include System::Model::Unid
  include System::Model::Unid::Creator
  include System::Model::Unid::Recognition
  include System::Model::Unid::Publication
  include System::Model::Unid::Commitment
  include System::Model::Base::Content

  belongs_to :status,  :foreign_key => :state,      :class_name => 'System::Base::Status'
  
  validates_presence_of :state, :sort_no, :title, :url
  
  def self.get_targets
    {'' => '通常', 'blank' => '別ウィンドウ'}
  end
  
  def get_attributes
    attr = {}
    attr[:target] = self.target if self.target.to_s != ''
    return attr
  end
end
