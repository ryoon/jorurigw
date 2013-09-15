class Doclibrary::File < Gwboard::CommonDb
  include System::Model::Base
  include System::Model::Base::Content
  include Cms::Model::Base::Content
  include Doclibrary::Model::Systemname
  include Gwboard::Model::AttachFile
  include Gwboard::Model::AttachesFile

  belongs_to :status, :foreign_key => :state,    :class_name => 'System::Base::Status'
  belongs_to :parent, :foreign_key => :parent_id, :class_name => 'Doclibrary::Doc'

  validates_presence_of :filename, :message => "ファイルが指定されていません。"

  def search(params)
    params.each do |n, v|
      next if v.to_s == ''
      case n
      when 'kwd'
        and_keywords v, :filename
      end
    end if params.size != 0

    return self
  end

  def item_path
    return "#{Site.current_node.public_uri.chop}?title_id=#{self.title_id}&p_id=#{self.parent_id}"
  end

  def item_parent_path(params=nil)
    if params.blank?
      state = 'CATEGORY'
    else
      state = params[:state]
    end
    ret = "#{Site.current_node.public_uri}#{self.parent_id}?title_id=#{self.title_id}&cat=#{self.parent.category1_id}" unless state == 'GROUP'
    ret = "#{Site.current_node.public_uri}#{self.parent_id}/?title_id=#{self.title_id}&gcd=#{self.parent.section_code}" if state == 'GROUP'
    return ret
  end

  def delete_path
    return "#{Site.current_node.public_uri}#{self.id}/delete?title_id=#{self.title_id}&p_id=#{self.parent_id}"
  end

  def edit_memo_path(title,item)
    if title.form_name == 'form002'
      return "#{Site.current_node.public_uri}#{item.id}/edit_file_memo/#{self.id}?title_id=#{self.title_id}"
    else
      return "#{Site.current_node.public_uri}#{self.parent_id}/edit_file_memo/#{self.id}?title_id=#{self.title_id}"
    end
  end

  def item_doc_path(title,item)
    if title.form_name=='form002'
      return "#{Site.current_node.public_uri}#{item.id}?title_id=#{self.title_id}&cat=#{self.parent.category1_id}"
    else
      return "#{Site.current_node.public_uri}#{self.parent_id}?title_id=#{self.title_id}&cat=#{self.parent.category1_id}"
    end
  end

end
