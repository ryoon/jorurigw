class System::Session < ActiveRecord::Base
  include System::Model::Base
  set_table_name 'sessions'

  validates_presence_of     :session_id
end
