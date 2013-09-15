class Gw::IndPortalSetting < PassiveRecord::Base
  
  schema :max_contents => Integer
  
  def editable?
    return true
  end
  
  def self.read
    hash = Gw::Model::UserProperty.get('portal', :class_id => 3)
    if hash.blank?
      hash = Gw::NameValue.get_cache('yaml', nil, 'gw_ind_portal_settings_system_default')
    end
    item = self.new(self.convert_key_to_sym(hash))
    return item
  end
  
  def save(options)
    Gw::Model::UserProperty.save('portal', self.attributes, :class_id => 3)
  end
  
  def self.valid_user?(uid)
    return true if self.is_admin?(uid)
    return true if self.is_editor?(uid)
    return false
  end
  
  def self.is_admin?(uid)
    return true if System::Model::Role.get(1, uid, '_admin', 'admin') 
  end
  
  def self.is_editor?(uid)
    return true if System::Model::Role.get(1, uid, 'ind_portal', 'admin')
  end
  
  def self.max_contents_select_list
    list = []
    5.step(100,5) do |i|
      list << [i, i]
    end
    return list
  end
  
protected
  
  def self.convert_key_to_sym(hash)
    ret = {}
    hash.each_pair do |key,value|
      if value =~ /\d+/
        ret[key.to_sym] = value.to_i
      else
        ret[key.to_sym] = value
      end
    end
    return ret
  end
end