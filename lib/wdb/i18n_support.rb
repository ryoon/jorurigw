module Wdb::I18nSupport
  def self.included(mod)
    p "********************************"
    p "included from #{mod.model_name}."
    p mod.to_s.underscore
  end
  
  def transrate
    
  end
  
  alias transrate t
end
