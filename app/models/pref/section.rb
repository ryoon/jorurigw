class Pref::Section < ActiveRecord::Base
  include System::Model::Base
  include System::Model::Unid
  include System::Model::Unid::Creator
  include System::Model::Base::Content

  belongs_to :status,     :foreign_key => :state,         :class_name => 'System::Base::Status'
  has_one :group, :primary_key => :group_id, :foreign_key => :id, :class_name => 'System::Group'

  validates_presence_of :group_id, :state, :name

  def join_system_groups
    g = "#{System::Group.table_name}"
    self.join "INNER JOIN #{g} ON #{g}.id = #{self.class.table_name}.group_id"
  end

  def in_department
    join_system_groups
    self.and "system_groups.level_no", 2
  end

  def in_section
    join_system_groups
    self.and "system_groups.level_no", 3
  end

  def public_children
    item = self.class.new.public
    item.join_system_groups
    item.and  "system_groups.parent_id", group_id
    item.find(:all, :order => "pref_sections.group_id + 0")
  end

  def display_title
    return title if title.to_s != ''
    return group.name if group
    ''
  end

  def bread_crumbs(crumbs, options = {})
    make_crumb = Proc.new do |_i, _opt|
      {:name => _i.group.name, :uri => "#{_opt[:uri]}#{_i.name}/"}
    end

    crumbs.each do |c|
      if self.group && self.group.level_no == 3
        c << make_crumb.call(self.class.find_by_group_id(self.group.parent.id), options)
      end
      c << make_crumb.call(self, options)
    end
    crumbs
  end
end
