class Pref::Category < ActiveRecord::Base
  include System::Model::Base
  include System::Model::Tree
  include System::Model::Unid
  include System::Model::Unid::Creator
  include System::Model::Base::Content
  
  belongs_to :status,     :foreign_key => :state,      :class_name => 'System::Base::Status'
  
  validates_presence_of :state, :parent_id, :name, :title
  
  def public_children
    item = self.class.new.public
    item.parent_id = id
    item.find(:all, :order => :sort_no)
  end
  
  def bread_crumbs(crumbs, options = {})
    make_crumb = Proc.new do |_i, _opt|
      {:name => _i.title, :uri => "#{_opt[:uri]}#{_i.name}/"}
    end
    
    crumbs.each do |c|
      if level_no == 2
        p = self.class.find(parent_id)
        c << make_crumb.call(p, options)
      end
      c << make_crumb.call(self, options)
    end
    crumbs
  end
end
