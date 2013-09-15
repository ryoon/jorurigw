class Gwsub::Sb04LimitSetting < Gwsub::GwsubPref
  include System::Model::Base
  include Cms::Model::Base::Content

  validates_presence_of :limit
  validates_numericality_of :limit

  before_save :name_save

  def name_save
    self.updated_user  = Site.user.name
    self.updated_group = Site.user_group.name
  end
  def get_type_name
    if self.type_name == 'stafflistview_limit'
      type = "電子職員録"
    elsif self.type_name == 'divideduties_limit'
      type = "電子事務分掌表"
    else
      type = ""
    end
    type
  end
  def self.get_stafflistview_limit
    item = self.find(:first, :conditions => "type_name = 'stafflistview_limit'")
    if item.blank? || nz(item.limit, 0) == 0
      30
    else
      item.limit
    end
  end
  def self.get_divideduties_limit
    item = self.find(:first, :conditions => "type_name = 'divideduties_limit'")
    if item.blank? || nz(item.limit, 0) == 0
      30
    else
      item.limit
    end
  end
end
