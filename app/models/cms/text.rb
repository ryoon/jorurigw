class Cms::Text < ActiveRecord::Base
  include System::Model::Base
  include System::Model::Base::Content
  include System::Model::Unid
  include System::Model::Unid::Creator

  belongs_to :status,  :foreign_key => :state,      :class_name => 'System::Base::Status'
  
  validates_presence_of :state, :name, :title, :body
end
