class Pref::Area < ActiveRecord::Base
  include System::Model::Base
  include System::Model::Tree
  include System::Model::Unid
  include System::Model::Unid::Creator
  include System::Model::Base::Content
  
  belongs_to :status,  :foreign_key => :state,      :class_name => 'System::Base::Status'
  
  validates_presence_of :state, :name, :title
  
  def public_children
    item = Pref::Area.new.public
    item.parent_id = id
    item.find(:all, :order => :sort_no)
  end
  
  def bread_crumbs(crumbs, options = {})
    make_crumb = Proc.new do |_i, _opt|
      {:name => _i.title, :uri => "#{_opt[:uri]}#{_i.name}/"}
    end
    
    crumbs.each do |c|
      if level_no == 3
        parent = self.class.find(:first, :conditions => {:id => parent_id})
        if parent
          c << make_crumb.call(parent, options)
        end
      end
      c << make_crumb.call(self, options)
    end
    crumbs
  end
end
