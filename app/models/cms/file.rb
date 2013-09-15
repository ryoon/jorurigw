class Cms::File < ActiveRecord::Base
  include System::Model::Base
  include System::Model::Unid
  include System::Model::Unid::Creator
  include Cms::Model::Base::File
  
  validates_presence_of :name
  
  def upload_path
#    Rails.root + '/upload/cms/files' +
#      format('%08d', id).gsub(/(.*)(..)(..)(..)$/, '/\1/\2/\3/\4/') + name
    Rails.root + '/upload/cms/files' +
      format('%08d', id).gsub(/(.*)(..)(..)(..)$/, '/\1/\2/\3/\4/') +
      format('%07d', id) + '.dat'
  end
  
  def duplicated?
    file = self.class.new
    file.and :id, "!=", id
    file.and :name, name
    file.and :parent_unid, parent_unid
    return file.find(:first)
  end
end
