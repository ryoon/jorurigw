class Doclibrary::GroupFolder < Gwboard::CommonDb
  include System::Model::Base
  include System::Model::Base::Content
  include System::Model::Tree
  include Cms::Model::Base::Content

  belongs_to :status, :foreign_key => :state, :class_name => 'System::Base::Status'
  belongs_to :use_status, :foreign_key => :use_state, :class_name => 'System::Base::Status'

  acts_as_tree :order=>'sort_no'

  validates_presence_of :state, :name

  def status_name
    {'public' => '公開', 'closed' => '非公開'}
  end

  def level1
    self.and :level_no, 1
    return self
  end

  def level2
    self.and :level_no, 2
    return self
  end

  def level3
    self.and :level_no, 3
    return self
  end

  def search(params)
    params.each do |n, v|
      next if v.to_s == ''
      case n
      when 'kwd'
        search_keyword v, :name
      end
    end if params.size != 0

    return self
  end

  def item_home_path
    return '/doclibrary/'
  end

  def link_list_path
    return "#{Site.current_node.public_uri}?title_id=#{self.title_id}&state=GROUP&grp=#{self.id}&gcd=#{self.code}"
  end

  def item_path
    return "#{Site.current_node.public_uri}?title_id=#{self.title_id}&state=GROUP&grp=#{self.parent_id}&gcd=#{self.code}"
  end

  def show_path
    return "#{Site.current_node.public_uri}#{self.id}?title_id=#{self.title_id}&state=GROUP&grp=#{self.parent_id}&gcd=#{self.code}"
  end

  def edit_path
    return "#{Site.current_node.public_uri}#{self.id}/edit?title_id=#{self.title_id}&state=GROUP&grp=#{self.parent_id}&gcd=#{self.code}"
  end

  def delete_path
    return "#{Site.current_node.public_uri}#{self.id}/delete?title_id=#{self.title_id}&state=GROUP&grp=#{self.parent_id}&gcd=#{self.code}"
  end

  def update_path
    return "#{Site.current_node.public_uri}#{self.id}/update?title_id=#{self.title_id}&state=GROUP&grp=#{self.parent_id}&gcd=#{self.code}"
  end

end
