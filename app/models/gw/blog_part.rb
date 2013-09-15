class Gw::BlogPart < Gw::Database
  include System::Model::Base
  include System::Model::Base::Config
  include Cms::Model::Base::Content
  
  validates_presence_of :title, :body
  validates_inclusion_of :state, :in => ['enabled', 'disabled', 'deleted'] 
  
  before_create :set_creator
  before_update :set_updator
  
  def set_default
    self.state = 'enabled'
    self.sort_no = Gw::BlogPart.next_sort_no 
    self.title = ""
    self.body = ""
  end
  
  def set_deleted
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
    self.created_user = Site.user.name
    self.created_group = Site.user_group.name
    self.updated_user = Site.user.name
    self.updated_group = Site.user_group.name
  end
  
  def set_updator
    self.updated_user = Site.user.name        
    self.updated_group = Site.user_group.name
  end
  
  def selected_by_user?(ids)
    return true if ids.index(self.id) != nil
    return false
  end
  
  def self.swap(item1, item2)
    if !item1.blank? && !item2.blank?
      begin
        transaction do
          item1.sort_no, item2.sort_no = item2.sort_no, item1.sort_no
          item1.save!
          item2.save!
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
    max_sort_item = Gw::BlogPart.find(:first, :order => "sort_no DESC")
    if max_sort_item.blank?
      max_sort_no = 0
    else
      max_sort_no = max_sort_item.sort_no
    end
    return max_sort_no + 10
  end
  
  def self.valid_user?(uid)
    return true if Gw::BlogPart.is_admin?(uid)
    return true if Gw::BlogPart.is_editor?(uid)
    return false
  end
  
  def self.is_admin?(uid)
    return true if System::Model::Role.get(1, uid, '_admin', 'admin') 
  end
  
  def self.is_editor?(uid)
    return true if System::Model::Role.get(1, uid, 'blog_part', 'admin')
  end
  
  def self.read_user_props
    props = Gw::Model::UserProperty.get('blogpart') || {}
    props['blogparts'] ||= []
    return props['blogparts']
  end
  
  def self.save_user_props(items)
    items ||= []
    props = {}
    props['blogparts'] = items
    Gw::Model::UserProperty.save('blogpart', props)
  end
  
  def self.get_ids_cond(uitems)
    cond = ""
    uitems.each_with_index do |uitem,idx|
      cond += "id = '#{uitem['id']}'"
      cond += " OR " if idx != uitems.length - 1
    end
    return cond
  end
  
  def self.get_user_items
    uitems = Gw::BlogPart.read_user_props
    if uitems.blank?
      items = []
    else
      cond = Gw::BlogPart.get_ids_cond(uitems)
      items = Gw::BlogPart.find(:all, :conditions => cond, :order => "sort_no ASC")
    end
    return items
  end
  
  def show_state
    status = [['enabled','有効'],['disabled','<span class="required">無効</span>']]
    state_str = status.assoc(self.state)
    return nil if state_str.blank?
    return state_str[1]
  end
  
  def self.state_select_list
    [['有効','enabled'],['無効','disabled']]
  end
  
  def search(params)
    self.and 'state', '!=', 'deleted'
    params.each do |key, value|
      next if value.to_s == ''
      case key
        when 's_keyword'
        words = value.split(/[ 　]+/)
        if words.length != 0
          words.each do |word|
            self.and 'title', 'like', "%#{word}%"
          end
        end
      end
    end if params.size != 0
    return self
  end
end