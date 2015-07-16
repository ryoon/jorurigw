class Pref::Attribute < ActiveRecord::Base
  include System::Model::Base
  include System::Model::Unid
  include System::Model::Unid::Creator
  include System::Model::Base::Content
  
  belongs_to :status,  :foreign_key => :state,      :class_name => 'System::Base::Status'
  
  validates_presence_of :state, :name, :title
  
  def bread_crumbs(crumbs, options = {})
    make_crumb = Proc.new do |_i, _opt|
      {:name => _i.title, :uri => "#{_opt[:uri]}#{_i.name}/"}
    end
    
    crumbs.each do |c|
      c << make_crumb.call(self, options)
    end
    crumbs
  end
end