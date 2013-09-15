class System::RoleName < ActiveRecord::Base
  include System::Model::Base
  include System::Model::Base::Config

  validates_presence_of :display_name, :table_name, :sort_no
  validates_uniqueness_of :table_name, :display_name
  validates_numericality_of :sort_no

end
