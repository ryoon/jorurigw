class Cms::Page < ActiveRecord::Base
  include System::Model::Base
  include System::Model::Unid
  include System::Model::Unid::Creator
  include System::Model::Unid::Inquiry
  include System::Model::Unid::Recognition
  include System::Model::Unid::Publication
  include System::Model::Unid::Commitment
  include System::Model::Unid::Task
  include Cms::Model::File
  include Cms::Model::Base::Content

  belongs_to :status,  :foreign_key => :state,     :class_name => 'System::Base::Status'
  belongs_to :node,    :foreign_key => :node_id,   :class_name => 'Cms::Node'
  belongs_to :layout,  :foreign_key => :layout_id, :class_name => 'Cms::Layout'

  validates_presence_of :state, :name, :title

  attr_accessor :input_mode, :import_data

  def states
    {'public' => '公開'}
  end

  before_save :publish_at_once
  def publish_at_once
    if state == 'public'
      self.published_at = Core.now
    end
    return true
  end

  def public_files_path
    File.dirname(public_path) + '/' + name + '.files'
  end

  def public_uri
    node.public_uri + name
  end

  def bread_crumbs(crumbs, options = {})
    make_crumb = Proc.new do |_i, _opt|
      {:name => _i.title, :uri => "#{_opt[:uri]}#{_i.name}/"}
    end

    crumbs.each do |c|
      c << make_crumb.call(self, options)
    end if name != 'index.html'
    crumbs
  end
end