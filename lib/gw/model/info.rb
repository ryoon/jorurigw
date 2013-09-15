module Gw::Model::Info
  def self.remind
    item = Gw::Info.new
    d = Date.today
    items = item.find(:all, :order => 'updated_at',
      :conditions => remind_cond(d))
    return items.collect{|x| { :date_str => x.updated_at.strftime("%m/%d %H:%M"), :cls => x.cls, :title => x.title, :date_d => x.updated_at}}
  end
  def self.remind_cond(d)
    "(updated_at > '#{(d - 7).strftime('%Y-%m-%d 0:0:0')}')"
  end
end
