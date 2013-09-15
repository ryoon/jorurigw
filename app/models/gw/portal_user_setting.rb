class Gw::PortalUserSetting < Gw::Database
  include System::Model::Base
  include System::Model::Unid
  include System::Model::Unid::Creator
  include Cms::Model::Base::Content
end
