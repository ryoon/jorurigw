class System::GroupUpdate < ActiveRecord::Base
  include System::Model::Base
  include System::Model::Tree
  include System::Model::Base::Config

  belongs_to :grp         , :foreign_key => :group_id         ,  :class_name => 'System::GroupHistoryTemporary'
  belongs_to :parent      , :foreign_key => :parent_id        ,  :class_name => 'System::GroupHistoryTemporary'
  has_many   :group_next  , :foreign_key => :group_update_id  ,  :class_name => 'System::GroupNext' ,:dependent=>:destroy

  validates_presence_of :start_at,:state
  validates_presence_of :parent_code,:parent_name,:level_no,:code,:name   if (:state=='1' or :state=='2')
  validates_presence_of :group_id  if (:state=='3' or :state=='6')

  before_save :before_save_set_column

  def before_save_set_column
    case self.state.to_i
    when 1
      if self.group_id.to_i==0
        if self.code.blank? or self.name.blank? or self.level_no.to_i==0
        else
          g               = System::GroupHistoryTemporary.new
          g.state         = 'enabled'
          g.level_no      = self.level_no
          g.code          = self.code
          g.order         "start_at DESC , (end_at Is NULL) ,end_at DESC"
          groups          = g.find(:first)
          self.group_id   = groups.id         unless groups.blank?
          self.parent_id  = groups.parent_id  unless groups.blank?
        end
      else

      end
    when 2
      if self.group_id.to_i==0
        if self.code.blank? or self.name.blank? or self.level_no.to_i==0
        else
          self.group_id   = 0
          p               = System::GroupHistoryTemporary.new
          p.state         = 'enabled'
          p.level_no      = self.level_no.to_i - 1
          p.code          = self.parent_code
          p.name          = self.parent_name
          p.order         "start_at DESC , (end_at Is NULL) ,end_at DESC"
          parents         = p.find(:first)
          self.parent_id  = parents.id  unless parents.blank?

          self.parent_id  = 0           if     parents.blank?
        end
      end
    when 3
      if self.group_id.to_i==0
        if self.code.blank? or self.name.blank? or self.level_no.to_i==0
        else
          g               = System::GroupHistoryTemporary.new
          g.state         = 'enabled'
          g.level_no      = self.level_no
          g.code          = self.code
          g.name          = self.name
          g.order         "start_at DESC , (end_at Is NULL) ,end_at DESC"
          groups          = g.find(:first)
          self.group_id   = groups.id         unless groups.blank?
          self.parent_id  = groups.parent_id  unless groups.blank?
        end
      else
        self.level_no     = self.grp.level_no
        self.code         = self.grp.code
        self.name         = self.grp.name
        self.parent_id    = self.grp.parent_id
        self.parent_code  = self.grp.parent.code
        self.parent_name  = self.grp.parent.name
      end
    when 6
      if self.group_id.to_i==0
        if self.code.blank? or self.name.blank? or self.level_no.to_i==0
        else
          g               = System::GroupHistoryTemporary.new
          g.state         = 'enabled'
          g.level_no      = self.level_no
          g.code          = self.code
          g.name          = self.name
          g.order         "start_at DESC , (end_at Is NULL) ,end_at DESC"
          groups          = g.find(:first)
          self.group_id   = groups.id         unless groups.blank?
          self.parent_id  = groups.parent_id  unless groups.blank?
        end
      else
        self.level_no     = self.grp.level_no
        self.code         = self.grp.code
        self.name         = self.grp.name
        self.parent_id    = self.grp.parent_id
        self.parent_code  = self.grp.parent.code
        self.parent_name  = self.grp.parent.name
      end
    else
    end
  end

  def self.state(all=nil)
    states = Gw.yaml_to_array_for_select 'system_group_updates_state'
    states = [['すべて','0']] + states if all=='all'
    return states
  end

  def self.state_show(state)
    options = {:rev=>true}
    states = Gw.yaml_to_array_for_select('system_group_updates_state',options)
    show_value = states.assoc(state.to_i)
    return nil if show_value.blank?
    return show_value[1]
  end

  def self.convert_state(state)
    options = {:rev=>false}
    states = Gw.yaml_to_array_for_select('system_group_updates_state',options)
    show_value = states.assoc(state)
    return nil if show_value.blank?
    return show_value[1]
  end

  def self.truncate_table
    connect = self.connection()
    truncate_query = "TRUNCATE TABLE `system_group_updates` ;"
    connect.execute(truncate_query)
  end

end
