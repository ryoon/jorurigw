class Gw::ScheduleUserMoveLog < Gw::Database
  include System::Model::Base
  include Cms::Model::Base::Content

  before_create :set_creator

  def set_creator
    self.created_at   = Time.now
    self.created_uid  = Site.user.id
    self.created_gid  = Site.user_group.id
  end

  def self.save_data(state = nil, schedule_id = nil, uid = nil)

    if !state.blank? && !schedule_id.blank? && !uid.blank?
      item = self.new
      item.state        = state
      item.schedule_id  = schedule_id
      item.uid          = uid
      item.save(false)
    end
  end

end
