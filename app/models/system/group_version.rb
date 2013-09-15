class System::GroupVersion < ActiveRecord::Base
  include System::Model::Base
  include System::Model::Tree
  include System::Model::Base::Config

  has_many :groups,         :foreign_key => :version_id,          :class_name => 'System::Group' ,        :dependent => :destroy
  has_many :grouphistory,   :foreign_key => :current_version_id,  :class_name => 'System::GroupHistory' , :dependent => :destroy
  validates_presence_of :version , :start_at

  def self.get_current_group_version_id(fyear_id = nil , date = nil)
    if fyear_id.to_i != 0
      ids = Gw::YearFiscalJp.find(:all,:order=>'id').collect{|x| x.id}
      check = ids.index(fyear_id)
      if check == nil
        today = Time.now
      else
        today = Gw::YearFiscalJp.find(fyear_id).start_at
      end
      v_cond  = "start_at <= #{today}"
      v_order = "start_at DESC"
      version = System::GroupVersion.find(:first , :conditions=>v_cond , :order=>v_order)
      return version.id unless version.blank?
      return 1 if version.blank?
    end

    if date != nil
      today = date
      version_condition = "start_at <= '#{today}'"
      version = System::GroupVersion.find(:first , :conditions=>version_condition , :order=>"start_at DESC")
      return version.id
    end

    today = Core.now
    version_condition = "start_at <= '#{today}'"
    version = System::GroupVersion.find(:first , :conditions=>version_condition , :order=>"start_at DESC")
    return version.id
  end

  def self.get_next_group_version_id
    _today = Core.now
    _version_condition = "start_at > '#{_today}'"
    _next_version = System::GroupVersion.find(:last , :conditions=>_version_condition , :order=>"start_at DESC")
    if  _next_version == nil
        _next_version_id = nil
    else
        _next_version_id = _next_version.id
    end
    return _next_version_id
  end

  def search(params)
    params.each do |n, v|
      next if v.to_s == ''

      case n
      when 's_keyword'
        search_keyword v, :version
      end
    end if params.size != 0

    return self
  end

end
