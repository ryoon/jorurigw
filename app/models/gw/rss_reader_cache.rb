class Gw::RssReaderCache < Gw::Database
  include System::Model::Base
  include Cms::Model::Base::Content
  
  belongs_to :rss_reader, :class_name => 'Gw::RssReader' , :foreign_key => :rrid
  
end
