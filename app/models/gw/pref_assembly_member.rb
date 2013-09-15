# -*- encoding: utf-8 -*-
class Gw::PrefAssemblyMember < Gw::Database
  include System::Model::Base
  include Cms::Model::Base::Content

  validates_presence_of :g_name, :g_order, :u_name,:u_lname, :u_order

  before_create :set_creator
  before_update :set_updator

  def self.editable?(uid = Site.user.id)
    return true if self.is_admin?(uid) == true
    return true if self.is_dev?(uid) == true
    return false
  end

  def self.is_admin?( uid = Site.user.id )
    is_admin = System::Model::Role.get(1, uid ,'gw_pref_assembly', 'admin')
    return true if is_admin == true
    gw_admin = System::Model::Role.get(1, uid ,'_admin', 'admin')
    return true if gw_admin == true
    return false
  end

  def self.is_dev?(uid = Site.user.id)
    System::Model::Role.get(1, uid ,'gwsub', 'developer')
  end

  def set_creator
    self.created_at     = Time.now
    self.created_user   = Site.user.name unless Site.user.blank?
    self.created_group  = Site.user_group.id unless Site.user.blank?
  end

  def set_updator
    self.updated_at     = Time.now
    self.updated_user   = Site.user.name unless Site.user.blank?
    self.updated_group  = Site.user_group.id unless Site.user.blank?
  end

  def self.truncate_table
    connect = self.connection()
    truncate_query = "TRUNCATE TABLE `gw_pref_assembly_members` ;"
    connect.execute(truncate_query)
  end

  def self.state_select
    states = [['在席','on'],['不在','off']]
    return states
  end

  def self.state_show(state)
    states = [['on','在席'],['off','不在']]
    show = states.assoc(state)
    return show[1] unless show.blank?
    return ''
  end
end
