class System::GroupChangePickup < ActiveRecord::Base
  include System::Model::Base
  include System::Model::Tree
  include System::Model::Base::Config

  validates_presence_of :target_at

end
