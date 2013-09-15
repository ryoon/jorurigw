class Gwqa::File < Gwboard::CommonDb
  include System::Model::Base
  include System::Model::Base::Content
  include Gwqa::Model::Systemname
  include Gwboard::Model::AttachFile
  include Gwboard::Model::AttachesFile

  belongs_to :status, :foreign_key => :state, :class_name => 'System::Base::Status'

  validates_presence_of :filename, :message => "ファイルが指定されていません。"

  def item_path
    return "#{Site.current_node.public_uri.chop}?title_id=#{self.title_id}&p_id=#{self.parent_id}"
  end

  def delete_path
    return "#{Site.current_node.public_uri}#{self.id}/delete?title_id=#{self.title_id}&p_id=#{self.parent_id}"
  end

end
