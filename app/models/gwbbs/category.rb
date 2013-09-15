class Gwbbs::Category < Gwboard::CommonDb
  include System::Model::Base
  include System::Model::Base::Content
  include System::Model::Tree
  include Gwbbs::Model::Systemname

  belongs_to :status, :foreign_key => :state, :class_name => 'System::Base::Status'
  acts_as_tree :order=>'sort_no'
  validates_presence_of :state, :sort_no, :name

  def max_line
    return 30
  end

  def link_list_path
    return "#{Site.current_node.public_uri}?title_id=#{self.title_id}"
  end

  def item_path
    return "#{Site.current_node.public_uri}?title_id=#{self.title_id}"
  end

  def show_path
    return "#{Site.current_node.public_uri}#{self.id}?title_id=#{self.title_id}"
  end

  def edit_path
    return "#{Site.current_node.public_uri}#{self.id}/edit?title_id=#{self.title_id}"
  end

  def delete_path
    return "#{Site.current_node.public_uri}#{self.id}/delete?title_id=#{self.title_id}"
  end

  def update_path
    return "#{Site.current_node.public_uri}#{self.id}/update?title_id=#{self.title_id}"
  end


end
