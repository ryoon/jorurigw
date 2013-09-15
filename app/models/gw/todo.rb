class Gw::Todo < Gw::Database
  include System::Model::Base
  include Cms::Model::Base::Content
  validates_presence_of :title
  gw_validates_datetime :ed_at, :allow_blank=>1

  validate_on_create :validate_count

  def validate_count
    self.errors.add 'ToDo', 'は２００件以上登録することができません。' if self.class.get_count >= 200
  end

  def self.get_count(uid = Site.user.id)
    todos = Gw::Todo.find(:all, :conditions=>"uid=#{uid}")
    return todos.size
  end

  def self.cond(uid = nil)
    return "" if uid.nil? && (Site.user.nil? || Site.user.id.nil?)
    uid = Site.user.id if uid.nil?
    return "class_id = 1 and uid = #{uid}"
  end

  def _title(chop_length = 20)
    return !title.blank? ? title : Gw.chop_str(body, chop_length)
  end

  def self.finished_select
    item = [['未完了', 0],['完了', 1]]
    return item
  end
  def self.finished_show(finished)
    return "未完了" if finished.blank?
    item = [[0, '未完了'],[1, '完了']]
    show_str = item.assoc(nz(finished, 0))
    if show_str.blank?
      return nil
    else
      return show_str[1]
    end
  end

end
