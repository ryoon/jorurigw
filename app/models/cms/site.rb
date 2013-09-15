class Cms::Site < ActiveRecord::Base
  include System::Model::Base
  include System::Model::Unid
  include System::Model::Unid::Creator
  include Cms::Model::Base::Content
  
  belongs_to :status,  :foreign_key => :state,      :class_name => 'System::Base::Status'
  
  validates_presence_of :state, :domain, :name
  
  def states
    {'public' => '公開'}
  end
  
  def public_uri
    #Site.uri + path + '/'
  end
  
  def upload_path
    #Site.upload_path + '/contents'
  end
  
  def mobile?
    return mobile_is == 1 ? true : nil
  end
end
