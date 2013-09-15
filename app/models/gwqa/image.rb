class Gwqa::Image < Gwboard::CommonDb
  include System::Model::Base
  include System::Model::Base::Content
  include Gwboard::Model::AttachFile
  include Gwqa::Model::Systemname

  has_attachment :content_type => :image,
    :storage => :file_system,
    :max_size => 5.megabytes,
    :size => 0.megabyte..10.megabytes

  validates_as_attachment

  validates_presence_of :filename, :message => "ファイルが指定されていません。"

  def image_file_path
    ret = ""
    if self.parent_name.size == 8
      str = sprintf("%08d",self.id)
      str = "#{str[0..3]}/#{str[4..7]}/"
      ret = "/_common/modules/#{self.system_name}/#{sprintf('%06d',self.title_id)}/#{self.parent_name}/#{str}#{self.filename}"
    else
      ret = "/_common/modules/#{self.system_name}/#{sprintf('%06d',self.title_id)}/#{self.parent_name}/#{self.filename}"
    end
    return ret
  end

  def delete_path
    return "#{Site.current_node.public_uri}#{self.id}/delete?title_id=#{self.title_id}&p_id=#{self.parent_id}"
  end

  def image_delete(root)
    str = sprintf("%08d",self.id)
    str = str[0..3] + '/' + str[4..7] + '/'
    path = root + sprintf("%06d",self.title_id) + "/" + self.parent_name + '/' + str

    deleteall(path)

  end

  def image_delete_all(root)
    str = sprintf("%08d",self.id)
    str = str[0..3] + '/' + str[4..7] + '/'
    path = root + sprintf("%06d",self.title_id) + "/" + self.parent_name + '/'

    deleteall(path)

  end

end
