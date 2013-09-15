class Cms::TmpFile < ActiveRecord::Base
  include System::Model::Base
  include Cms::Model::Base::File

  validates_presence_of :name

  def upload_path
    Rails.root + '/upload/cms/tmp_files' +
      format('%08d', id).gsub(/(.*)(..)(..)(..)$/, '/\1/\2/\3/\4/') +
      format('%07d', id) + '.dat'
  end

  def duplicated?
    file = self.class.new
    file.and :id, "!=", id
    file.and :name, name
    file.and :tmp_id, tmp_id
    return file.find(:first)
  end
end
