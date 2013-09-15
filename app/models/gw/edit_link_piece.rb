class Gw::EditLinkPiece < Gw::Database
  include System::Model::Base
  include System::Model::Base::Config
  include Cms::Model::Base::Content

  belongs_to :parent, :class_name => 'Gw::EditLinkPiece' , :foreign_key => :parent_id
  has_many :children, :class_name => 'Gw::EditLinkPiece' , :foreign_key => :parent_id

  belongs_to :css, :class_name => 'Gw::EditLinkPieceCss' , :foreign_key => :block_css_id
  belongs_to :icon, :class_name => 'Gw::EditLinkPieceCss' , :foreign_key => :block_icon_id

  validates_presence_of     :name,:sort_no
  validates_presence_of     :link_url        ,:if => Proc.new{ |item| item.level_no == 4 }
  validates_presence_of     :field_account   ,:if => Proc.new{ |item| item.class_sso == 2 }
  validates_presence_of     :field_pass      ,:if => Proc.new{ |item| item.class_sso == 2 }
  validates_presence_of     :ssoid           ,:if => Proc.new{ |item| item.class_sso == 2 && item.uid != nil }
  validates_presence_of     :parent_id
  validates_uniqueness_of   :sort_no        ,:scope=>:parent_id
  validate :validate_tab_keys

  before_create :set_creator
  before_update :set_updator
  after_save :reset_block_css_id

  def self.is_dev?(uid = Site.user.id)
    System::Model::Role.get(1, uid ,'gwsub', 'developer')
  end

  def self.is_admin?(uid = Site.user.id)
    System::Model::Role.get(1, uid ,'edit_link_piece', 'admin')
  end

  def self.is_editor?(uid = Site.user.id)
    System::Model::Role.get(1, uid ,'edit_link_piece', 'editor')
  end

  def validate_tab_keys
    unless self.level_no == 2
      return true
    end
    if self.tab_keys == 0
      errors.add :tab_keys, 'は０以外の数値を入力してください。'
      return false
    end
    cond = "level_no=2 and tab_keys=#{self.tab_keys}"
    check = Gw::EditLinkPiece.find(:all,:conditions=>cond)
    if check.blank?
      return true
    else
      if check.size==1 and check[0].id==self.id
        return true
      end
      errors.add :tab_keys, 'はすでに登録されています。'
      return false
    end
    return true
  end

  def self.published_select
    published = [['公開','opened'],['非公開','closed']]
    return published
  end

  def self.published_show(published)
    publishes = [['closed','非公開'],['opened','公開']]
    show_str = publishes.assoc(published)
    if show_str.blank?
      return nil
    else
      return show_str[1]
    end
  end

  def self.state_select
    status = [['有効','enabled'],['無効','disabled']]
    return status
  end

  def self.state_show(state)
    status = [['deleted','削除済'],['disabled','無効'],['enabled','有効']]
    show_str = status.assoc(state)
    if show_str.blank?
      return nil
    else
      return show_str[1]
    end
  end

  def self.other_ctrl_select
    other_ctrls = [['する',1],['しない',2]]
    return other_ctrls
  end

  def self.other_ctrl_show(other_ctrl)
    other_ctrls = [[1,'する'],[2,'しない']]
    show_str = other_ctrls.assoc(other_ctrl)
    if show_str.blank?
      return nil
    else
      return show_str[1]
    end
  end

  def self.external_select
    externals = [['内部',1],['外部',2]]
    return externals
  end

  def self.external_show(class_external)
    externals = [[1,'内部'],[2,'外部']]
    show_str = externals.assoc(class_external)
    if show_str.blank?
      return nil
    else
      return show_str[1]
    end
  end

  def self.sso_select
    ssos = [['しない',1],['する',2]]
    return ssos
  end

  def self.sso_show(class_sso)
    ssos = [[1,'しない'],[2,'する']]
    show_str = ssos.assoc(class_sso)
    if show_str.blank?
      return nil
    else
      return show_str[1]
    end
  end

  def self.level_show(level_no)
    level_str = [[1,'TOP'],[2,'ピース'],[3,'ブロック'],[4,'リンク']]
    show_str = level_str.assoc(level_no)
    if show_str.blank?
      return nil
    else
      return show_str[1]
    end
  end

  def get_child(options={})
    if options[:published]
      cond  = "published = '#{options[:published]}' and state != 'deleted' and parent_id=#{self.id}"
    else
      cond  = "state != 'deleted' and parent_id=#{self.id}"
    end
    order = "sort_no"
    childrens = Gw::EditLinkPiece.find(:all , :conditions=>cond , :order => order )
    return childrens
  end

  def parent_tree
    Util::Tree.climb(id, :class => self.class)
  end

  def set_creator
    self.created_user   = Site.user.name
    self.created_group  = Site.user_group.name
  end

  def set_updator
    self.updated_user   = Site.user.name
    self.updated_group  = Site.user_group.name
  end

  def self.get_user_items
    items = self.get_user_roots
    if items.blank?
      item = self.create_user_default_item(Site.user)
      if item.blank?
        items = []
      else
        items = [item]
      end
    end
    self.validate_bookmark
    return items
  end

  def self.next_sort_no(pid)
    cond  = "state!='deleted' AND parent_id=#{pid} AND uid=#{Site.user.id}"
    order = "sort_no DESC"
    max_sort_item = Gw::EditLinkPiece.find(:first, :conditions => cond, :order => order)
    if max_sort_item.blank?
      max_sort_no = 0
    else
      max_sort_no = max_sort_item.sort_no
    end
    return max_sort_no + 10
  end

  def self.next_tab_keys
    max_tab_item = Gw::EditLinkPiece.find(:first, :order => "tab_keys DESC")
    if max_tab_item.blank?
      max_tab_keys = 0
    else
      max_tab_keys = max_tab_item.tab_keys
    end
    return max_tab_keys + 10
  end

  def self.swap(item1, item2)
    begin
      transaction do
        item1.sort_no, item2.sort_no = item2.sort_no, item1.sort_no
        item1.save(false)
        item2.save(false)
      end
    rescue => e
      case e.class.to_s
      when 'ActiveRecord::RecordInvalid', 'Gw::ARTransError'
      else raise e
      end
    end
  end

  def get_valid_children
    cond  = "published='opened' AND state!='deleted' AND parent_id=#{self.id} AND uid=#{Site.user.id}"
    order = "sort_no"
    children = Gw::EditLinkPiece.find(:all, :order => order, :conditions => cond)
    children.reject! do |child|
      !child.valid_display_auth?
    end
    return children
  end

  def set_default_ind_base
    self.uid             = Site.user.id
    self.state           = 'enabled'
    self.published       = 'opened'
    self.tab_keys        = 0
    self.class_created   = 1
    self.class_external  = 1
    self.class_sso       = 1
    return self
  end

  def set_default_ind(parent)
    self.set_default_ind_base
    unless parent.blank?
      self.parent_id       = parent.id
      self.level_no        = parent.level_no + 1
      self.sort_no         = Gw::EditLinkPiece.next_sort_no(parent.id)
      self.block_icon_id   = Gw::EditLinkPiece.get_default_block_icon_id(parent)
      self.block_css_id    = Gw::EditLinkPiece.get_default_block_css_id(parent)
    end
    return self
  end

  def set_deleted
    self.published      = 'closed'
    self.state          = 'deleted'
    self.tab_keys       = nil
    self.sort_no        = nil
    self.deleted_at     = Time.now
    self.deleted_user   = Site.user.name
    self.deleted_group  = Site.user_group.name
    return self
  end

  def save_deleted
    self.set_deleted
    self.save(false)
  end

  def reset_block_css_id
    if self.level_no == 3 && self.uid != nil
      begin
        transaction do
          css1 = Gw::EditLinkPiece.find_block_css_repeat1
          css2 = Gw::EditLinkPiece.find_block_css_repeat2
          if !css1.blank? && !css2.blank?
            first = true
            self.parent.get_valid_children.each do |item|
              if first
                if item.block_css_id != css1.id
                  item.block_css_id = css1.id
                  item.save!
                end
              else
                if item.block_css_id != css2.id
                  item.block_css_id = css2.id
                  item.save!
                end
              end
              if first && item.published == 'opened'
                 first = false
              end
            end
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

  def enabled?
    return self.state == 'enabled'
  end

  def disabled?
    return self.state == 'disabled'
  end

  def deleted?
    return self.state == 'deleted'
  end

  def opened?
    return self.published == 'opened'
  end

  def closed?
    return self.published == 'closed'
  end

  def expandable?
    return false if self.level_no == 4
    return true
  end

  def get_css_class
    css_class = ""
    unless self.block_css_id.blank?
      item = Gw::EditLinkPieceCss.find_by_id(self.block_css_id)
      if item.state == "enabled"
        css_class = item.css_class
      end
    end
    return css_class
  end

  def get_css_icon
    css_icon = ""
    unless self.block_icon_id.blank?
      item = Gw::EditLinkPieceCss.find_by_id(self.block_icon_id)
      if item.state == "enabled"
        css_icon = item.css_class
      end
    end
    return css_icon
  end

  def valid_display_auth?
    auth = true
    unless self.display_auth.blank?
      auth = eval(self.display_auth)
    end
    return auth
  end

  def get_link_url
    url = ""
    if self.class_sso == 2
      url = "/_admin/gw/link_sso/#{self.id}/redirect_pref_pieces"
    else
      url = self.link_url
    end
    return url
  end

  def get_link_tag
    a_tag = ""
    unless self.link_url.blank?
      a_tag = "<a "
      if self.disabled? || self.parent.disabled?
        a_tag += "href=\"##{self.get_link_url}\">"
      else
        a_tag += "target=\"_blank\" " if self.class_external == 2
        a_tag += "href=\"#{self.get_link_url}\">"
      end
    else
      a_tag = "<a>"
    end
    a_tag += self.name
    a_tag += "</a>"
    return a_tag
  end

  def get_state_color
    color = ""
    if self.state == 'enabled'
      color = ''
    else
      color = 'class="required"'
    end
    return color
  end

  def get_published_color
    color = ""
    if self.published == 'opened'
      color = ''
    else
      color = 'class="required"'
    end
    return color
  end

  def get_name_color
    color = ""
    if self.state == 'enabled' and self.published == 'opened'
      color = ''
    else
      color = 'class="required"'
    end
    return color
  end

  def get_tooltip
    if self.link_url.blank? && self.remark.blank?
      return ""
    elsif self.link_url.blank?
      return "#{self.remark}"
    elsif self.remark.blank?
      return "#{self.link_url}"
    end
    return "#{self.link_url}\n#{self.remark}"
  end

  def self.create_bookmark_item(name, link_url)
    bookmark = self.get_bookmark_block
    if bookmark
      item = Gw::EditLinkPiece.new
      item.set_default_ind(bookmark)
      item.name = name
      item.link_url = link_url
    end
    return item
  end

  def self.parent_select_list
    cond = "published='opened' AND state!='deleted' AND level_no=3 AND uid=#{Site.user.id}"
    order = "sort_no"
    items = Gw::EditLinkPiece.find(:all, :order => order, :conditions => cond)
    list = [["", ""]]
    items.each do |item|
      list << [item.name, item.id.to_s]
    end
    return list
  end

  def self.get_sso_select_list
    items = Gw::EditTab.find(:all, :conditions => "published='opened' AND state='enabled' AND class_sso=2")
    list = [["", "0"]]
    items.each do |item|
      list << [item.name, item.id.to_s]
    end
    return list
  end

  def self.get_sso_by_json(ssoid)
    item = Gw::EditTab.find(ssoid) rescue nil
    text = ""
    if item
      text = [item.field_account, item.field_pass, item.class_external.to_s, item.link_url].to_json
    else
      text += ["", "", "", ""].to_json
    end
    return text
  end

  def self.validate_bookmark
    bookmark  = self.get_bookmark_block
    if bookmark && bookmark.state != 'deleted'
      if bookmark.valid_bookmark?
        bookmark.state = 'enabled'
        bookmark.save
      else
        bookmark.state = 'disabled'
        bookmark.save
      end
      bookmark.children.each do |item|
        unless item.deleted?
          if item.valid_bookmark?
            item.state = 'enabled'
            item.save
          else
            item.state = 'disabled'
            item.save
          end
        end
      end
    end
  end

  def valid_bookmark?
    return Gw::Tool::Board.valid_url?(self.link_url)
  end

protected

  def self.create_user_default_item(user)
    root = Gw::EditLinkPiece.find(1) rescue nil
    if root.blank?
      return nil
    else
      new_item = Gw::EditLinkPiece.new
      new_item.set_default_ind(root)
    end
    begin
      transaction do
        new_item.name = "個人ポータル"
        new_item.sort_no = Gw::EditLinkPiece.next_sort_no(new_item.parent.id)
        new_item.tab_keys = Gw::EditLinkPiece.next_tab_keys
        new_item.uid = user.id
        new_item.save(false)
        Gw::EditLinkPiece.create_bookmark_block
      end
    rescue => e
      case e.class.to_s
      when 'ActiveRecord::RecordInvalid', 'Gw::ARTransError'
      else raise e
      end
    end
    return new_item
  end

  def self.get_default_block_icon_id(parent)
    icon_id = 0
    item = Gw::EditLinkPieceCss.find(:first, :conditions => "state!='deleted' AND css_name='リンク'")
    icon_id = item.id if item
    return icon_id
  end

  def self.find_block_css_repeat1
    return Gw::EditLinkPieceCss.find(:first, :conditions => "state!='deleted' AND css_name='繰返し１件目'")
  end

  def self.find_block_css_repeat2
    return Gw::EditLinkPieceCss.find(:first, :conditions => "state!='deleted' AND css_name='繰返し２件目以降'")
  end

  def self.get_default_block_css_id(parent)
    block_css_id = 0
    if parent.get_valid_children.length == 0
      item = Gw::EditLinkPiece.find_block_css_repeat1
      block_css_id = item.id if item
    else
      item = Gw::EditLinkPiece.find_block_css_repeat2
      block_css_id = item.id if item
    end
    return block_css_id
  end

  def self.get_portal_root
    cond  = "level_no=2 AND name='ポータル左　リンクピース'"
    order = "sort_no"
    return Gw::EditLinkPiece.find(:first, :order => order, :conditions => cond)
  end

  def self.get_user_roots
    cond  = "published='opened' AND state!='deleted' AND level_no=2 AND uid=#{Site.user.id}"
    order = "sort_no"
    return Gw::EditLinkPiece.find(:all, :order => order, :conditions => cond)
  end

  def self.find_bookmark_block
    cond  = "published='opened' AND state!='deleted' AND level_no=3 AND name='ブックマーク' AND uid=#{Site.user.id}"
    order = "sort_no DESC"
    bookmarks = Gw::EditLinkPiece.find(:all, :order => order, :conditions => cond)
    return bookmarks.length == 0 ? nil : bookmarks[0]
  end

  def self.create_bookmark_block
    cond  = "published='opened' AND state!='deleted' AND level_no=2 AND uid=#{Site.user.id}"
    root = Gw::EditLinkPiece.find(:first, :conditions => cond)
    item = nil
    if root
      item = Gw::EditLinkPiece.new
      item.set_default_ind(root)
      item.name = "ブックマーク"
      item.link_url = ""
      item.save(false)
    end
    return item
  end

  def self.get_bookmark_block
    bookmark = self.find_bookmark_block
    if bookmark.blank?
      roots = self.get_user_roots
      if roots.blank?
        item = self.create_user_default_item(Site.user)
        if item.blank?
          bookmark = nil
        else
          bookmark = self.find_bookmark_block
        end
      else
        bookmark = self.create_bookmark_block
      end
    end
    return bookmark
  end

  def self.get_bookmark_parent
    cond  = "published='opened' AND state!='deleted' AND level_no=3 AND uid=#{Site.user.id}"
    order = "sort_no"
    items = Gw::EditLinkPiece.find(:all, :order=>order, :conditions => cond)
    if items.blank?
      roots = Gw::EditLinkPiece.get_user_roots
      if roots.blank?
        defitem = Gw::EditLinkPiece.create_user_default_item(Site.user)
        items = defitem.children.select{ |x| x.level_no == 3 && x.sort_no == 10 }
      end
    end
    return items[0] unless items.blank?
    return nil
  end
end