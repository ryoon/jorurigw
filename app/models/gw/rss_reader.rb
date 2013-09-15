class Gw::RssReader < Gw::Database
  include System::Model::Base
  include System::Model::Base::Config
  include Cms::Model::Base::Content

  has_many :caches, :class_name => 'Gw::RssReaderCache', :foreign_key => :rrid, :dependent => :destroy

  validates_presence_of :title, :uri
  validates_length_of :max, :in => 1..10
  validates_inclusion_of :state, :in => ['enabled', 'disabled', 'deleted']
  validate :validate_uniqueness_of_uri

  before_create :set_creator
  before_update :set_updator

  def validate_uniqueness_of_uri
    unless self.uri.blank?
      items = find(:all, :conditions => "uri='#{self.uri}'")
      items.each do |item|
        next if item.id == self.id
        if item.state != 'deleted'
          errors.add :uri, "はすでに登録されています。"
          return false
        end
      end
    end
    return true
  end

  def set_default_value
    self.state = 'enabled'
    self.sort_no = Gw::RssReader.next_sort_no
    self.title = ""
    self.uri = ""
    self.max = 5
    self.interval = 60
  end

  def set_deleted_value
    self.state = 'deleted'
    self.deleted_at = Time.now
    self.deleted_user = Site.user.name
    self.deleted_group = Site.user_group.name
  end

  def enabled?
    state == 'enabled'
  end

  def disabled?
    state == 'disabled'
  end

  def deleted?
    state == 'deleted'
  end

  def set_creator
    if Site
      if Site.user
        self.created_user   = Site.user.name
        self.updated_user   = Site.user.name
      end
      if Site.user_group
        self.created_group  = Site.user_group.name
        self.updated_group  = Site.user_group.name
      end
    end
  end

  def set_updator
    if Site
      if Site.user
        self.updated_user = Site.user.name
      end
      if Site.user_group
        self.updated_group = Site.user_group.name
      end
    end
  end

  def sort_caches_by_id
    self.caches.sort! do |a,b|
      a.id <=> b.id
    end
  end

  def update_caches(checked_at)
    return unless self.state == 'enabled'
    feeds = Gw::Model::Rssreader.get_hash2(self.uri, self.max) rescue {}
    if feeds.blank?
      self.checked_at = checked_at
      self.save
    else
      fetched_at = Time.now
      begin
        transaction do
          self.checked_at = checked_at
          self.fetched_at = fetched_at
          self.save!
          Gw::RssReaderCache.destroy_all("rrid = '#{self.id}'")
          feeds.each do |feed|
            options = {
              :rrid => self.id, :uri => self.uri, :title => feed['title'],
              :link => feed['link'], :fetched_at => fetched_at, :published_at => feed['date']
            }
            Gw::RssReaderCache.new(options).save!
          end
        end
      rescue => e
        case e.class.to_s
        when 'ActiveRecord::RecordInvalid', 'Gw::ARTransError'
        else raise e
        end
      end
    end
  end

  def self.swap(id, sid)
    item = Gw::RssReader.find(id) rescue nil
    sitem = Gw::RssReader.find(sid) rescue nil
    if !item.blank? && !sitem.blank?
      begin
        transaction do
          item.sort_no, sitem.sort_no = sitem.sort_no, item.sort_no
          item.save!
          sitem.save!
        end
      rescue => e
        case e.class.to_s
        when 'ActiveRecord::RecordInvalid', 'Gw::ARTransError'
        else raise e
        end
      end
    end
  end

  def self.next_sort_no
    max_sort_item = Gw::RssReader.find(:first, :order => "sort_no DESC")
    if max_sort_item.blank?
      max_sort_no = 0
    else
      max_sort_no = max_sort_item.sort_no
    end
    return max_sort_no + 10
  end

  def self.valid_user?(uid)
    return true if Gw::RssReader.is_admin?(uid)
    return true if Gw::RssReader.is_editor?(uid)
    return false
  end

  def self.is_admin?(uid)
    return true if System::Model::Role.get(1, uid, '_admin', 'admin')
  end

  def self.is_editor?(uid)
    return true if System::Model::Role.get(1, uid, 'rss_reader', 'admin')
  end

  def self.read_rssids
    rssid_props = Gw::Model::UserProperty.get('rssid')
    rssid_props ||= {}
    rssid_props['rssids'] ||= []
    return rssid_props['rssids']
  end

  def self.save_rssids(rssids)
    rssid_props = {}
    rssid_props['rssids'] = rssids.sort
    rssid_props['rssids'] ||= []
    Gw::Model::UserProperty.save('rssid', rssid_props)
  end

  def self.checked_by_user?(item, rssids)
    return true if rssids.index(item.id) != nil
    return false
  end

  def self.update_all_caches
    items = Gw::RssReader.find(:all, :conditions => "state='enabled'")
    checked_at = Time.now
    for item in items
      if item.checked_at.to_i + item.interval*60 - 30 <= Time.now.to_i
        item.update_caches(checked_at)
      end
    end
  end

  def self.get_rssids_cond(rssids)
    cond = ""
    rssids.each_with_index do |rssid,idx|
      cond += "id = '#{rssid}'"
      if idx != rssids.length - 1
        cond += " OR "
      end
    end
    return cond
  end

  def self.get_user_items
    rssids = Gw::RssReader.read_rssids
    if rssids.blank?
      @items = []
    else
      cond = Gw::RssReader.get_rssids_cond(rssids)
      @items = Gw::RssReader.find(:all, :conditions => cond, :order => "sort_no ASC")
      @items.each do |item|
        item.sort_caches_by_id
      end
    end
    return @items
  end

  def self.show_state(state)
    status = [['enabled','有効'],['disabled','<span class="required">無効</span>']]
    state_str = status.assoc(state)
    return nil if state_str.blank?
    return state_str[1]
  end

  def self.state_select_list
    [['有効','enabled'],['無効','disabled']]
  end

  def self.max_select_list
    list = []
    for i in 1..10
      list << [i,i]
    end
    return list
  end

  def self.interval_select_list
    list = []
    10.step(60,10) do |n|
      list << [n,n]
    end
    90.step(360,30) do |n|
      list << [n,n]
    end
    return list
  end

  def search(params)
    self.and 'state', '!=', 'deleted'
    params.each do |type, word|
      next if type.to_s == ''
      case type
      when 's_keyword'
        words = word.split(/[ 　]+/)
        if words.length != 0
          self.and get_cond(words, [:title, :uri, :state])
        end
      end
    end if params.size != 0
    return self
  end

  def get_cond(words, columns)
    condition = Condition.new
    words.each do |word|
      cond = Condition.new
      columns.each_with_index do |col,idx|
        word = convert_state_word(col, word)
        cond.or col, "like", "%#{word}%"
      end
      condition.and cond
    end
    return condition
  end

  def convert_state_word(col, word)
    if col == :state
      return 'abled' if word.index("効") == 0
      return 'enabled' if word.index("有効") == 0 || word.index("有") == 0
      return 'disabled' if word.index("無効") == 0 || word.index("無") == 0
    end
    return word
  end
end