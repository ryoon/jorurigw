class Gw::Note < Gw::Database
  include System::Model::Base
  include System::Model::Base::Config
  include Cms::Model::Base::Content

  acts_as_list :scope => 'uid = #{Site.user.id}'
  
  validates_presence_of :title, :body
  
  def set_default(uid)
    self.title = ""
    self.body = ""
    self.uid = uid
  end
  
  def trim_body(len=30)
    return self.body.split(//u)[0...len].join + "..." if self.body.split(//u).length >= len
    return self.body
  end
  
  def get_tooltip_string
    strings = [self.body, " 作成日： "+Gw.datetime_str(self.created_at)];
    return strings.join("\n")
  end
  
  def self.read_props
    props = Gw::Model::UserProperty.get('note') || {}
    props['display_schedule'] ||= "0"
    return props
  end
  
  def self.save_props(props)
    props['display_schedule'] ||= "0"
    Gw::Model::UserProperty.save('note', props)
  end
  
  def self.get_data_for_schedule(d1, d2, uid, options={})
    ret = []
    props = Gw::Note.read_props
    if props['display_schedule'] == "1"
      cond = "uid = #{uid} AND '#{d1.strftime('%Y-%m-%d 0:0:0')}' <= deadline AND '#{d2.strftime('%Y-%m-%d 23:59:59')}' >= deadline"
      notes = Gw::Note.find(:all, :conditions => cond)
      notes.each do |item|
        ret.push({
            :date => Gw.datetime_to_date(item.deadline),
            :title => item.body,
            :delay => item.deadline ? false : Time.now > item.deadline,
            :title_raw => "[メモ] #{item.trim_body(16)}",
            :title_link => "/gw/notes/" + item.id.to_s,
            :class => 'category800',
            :id => "note#{item.id}",
            :item => item,
            :genre => :todo
        })
      end
    end
    return ret
  end
  
  def self.get_data_by_json(id)
    item = Gw::Note.find(id) rescue nil
    if item
      text = [item.id, item.title, item.body].to_json
    else
      text = ["", ""].to_json
    end
    return text
  end
end