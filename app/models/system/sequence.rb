class System::Sequence < ActiveRecord::Base
  set_table_name "system_sequences"
  
  named_scope :versioned, lambda{ |v| { :conditions => ["version = ?", "#{v}"] }}
end
