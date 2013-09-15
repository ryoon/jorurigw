class Pref::Doc < ActiveRecord::Base
  include System::Model::Base
  include System::Model::Unid
  include System::Model::Unid::Creator
  include System::Model::Unid::Inquiry
  include System::Model::Unid::Recognition
  include System::Model::Unid::Publication
  include System::Model::Unid::Commitment
  include System::Model::Unid::Task
  include System::Model::Unid::Tag
  include System::Model::Unid::Map
  include Cms::Model::File
  include Cms::Model::Base::Content
  include Pref::Model::Doc::Rel

  belongs_to :status,         :foreign_key => :state,             :class_name => 'System::Base::Status'
  belongs_to :notice_status,  :foreign_key => :notice_state,      :class_name => 'System::Base::Status'
  belongs_to :recent_status,  :foreign_key => :recent_state,      :class_name => 'System::Base::Status'
  belongs_to :list_status,    :foreign_key => :list_state,        :class_name => 'System::Base::Status'
  belongs_to :event_status,   :foreign_key => :event_state,       :class_name => 'System::Base::Status'
  belongs_to :content,        :foreign_key => :content_id,        :class_name => 'Cms::Content'
  belongs_to :attribute,      :foreign_key => :attribute_id,      :class_name => 'Pref::Attribute'
  
  validates_presence_of :state, :title, :body
  validates_presence_of :notice_state, :recent_state, :list_state
  validates_presence_of :language_id,  :attribute_id
  validates_length_of   :body, :maximum => 100000
  validates_length_of   :mobile_body, :maximum => 1000
  
  before_validation :modify_categories
  before_validation :validate_areas
  after_validation :validate_categories
  before_save :check_digit
  
  def modify_categories
    if category_ids.class == Array
      self.category_ids = category_ids.uniq.join(' ')
    end
  end
  
  def validate_categories
    if category_ids.to_s.size == 0
      errors.add '分野', 'を選択してください'
    #elsif dup
    #  errors.add '分野', 'が重複しています'
    end
  end
  
  def validate_areas
    if area_ids.class == Array
      self.area_ids = area_ids.join(' ')
    end
  end
  
  def notice_states
    {'visible' => '表示', 'hidden' => '非表示'}
  end
  
  def recent_states
    {'visible' => '表示', 'hidden' => '非表示'}
  end
  
  def list_states
    {'visible' => '表示', 'hidden' => '非表示'}
  end
  
  def event_states
    {'visible' => '表示', 'hidden' => '非表示'}
  end
  
  def public_path
    if name =~ /^[0-9]{13}$/
      _name = name.gsub(/^((\d{4})(\d\d)(\d\d)(\d\d)(\d\d).*)$/, '\2/\3/\4/\5/\6/\1')
    else
      _name = File.join(name[0..0], name[0..1], name[0..2], name)
    end
    Site.public_path + content.public_uri + _name + '/index.html'
  end
  
  def public_uri
    content.public_uri + name + '/'
  end
  
  def categories
    return @categories if @categories_found
    @categories = []
    category_ids.to_s.split(' ').uniq.each do |cid|
      if cate = Pref::Category.find(:first, :conditions => {:id => cid})
        @categories << cate
      end
    end
    @categories_found = true
    @categories
  end
  
  def areas
    return @areas if @areas_found
    @areas = []
    area_ids.to_s.split(' ').uniq.each do |cid|
      if area = Pref::Area.find(:first, :conditions => {:id => cid})
        @areas << area
      end
    end
    @areas_found = true
    @areas
  end
  
  def visible_in_notice
    #self.and 'language_id', 1
    self.and 'notice_state' , 'visible'
    self
  end
  
  def visible_in_recent
    self.and 'language_id', 1
    self.and 'recent_state' , 'visible'
    self
  end
  
  def visible_in_list
    #self.and 'language_id', 1
    self.and 'list_state' , 'visible'
    self
  end
  
  def is_event(options = {})
    self.and "language_id", 1
    if options[:year] && options[:month]
      sd = Date.new(options[:year], options[:month], 1)
      ed = sd >> 1
      self.and :event_date, 'IS NOT', nil
      self.and :event_date, '>=', sd
      self.and :event_date, '<' , ed
    end
  end
  
  def department_is(dep)
    join :creator
    ids = []
    dep.public_children.each do |c|
      ids << c.group_id
    end
    self.and 'system_creators.group_id', 'IN', ids
  end
  
  def section_is(sec)
    join :creator
    self.and 'system_creators.group_id', sec.group_id
  end
  
  def category_is(cate)
    self.and_in_ssv :category_ids, cate.id
  end
  
  def category_in(categories)
    tmp = []
    categories.each {|c| tmp << c.id}
    cids = '(' + tmp.join('|') + ')'
    self.and_in_ssv :category_ids, cids
  end
  
  def attribute_is(attr)
    self.and :attribute_id, attr
  end
  
  def attribute_in(attrs)
    self.and :attribute_id, 'IN', attrs
  end
  
  def has_area?(area_id)
    area_ids =~ /(^| )#{area_id}( |$)/
  end
  
  def area_is(area)
    self.and_in_ssv :area_ids, area.id
  end
  
  def check_digit
    return true if name.to_s != ''
    date = Date.strptime(Core.now, '%Y-%m-%d').strftime('%Y%m%d')
    date = created_at.strftime('%Y%m%d') if created_at
    seq  = Util::Sequencer.next_id('pref_docs', date)
    name = date + format('%04d', seq)
    self.name = Util::CheckDigit.check(name)
    return true
  end
  
  def bread_crumbs(crumbs, options = {})
    make_crumb = Proc.new do |_i, _opt|
      {:name => _i.title, :uri => "#{_opt[:uri]}#{_i.name}/"}
    end
    
    crumbs.each_with_index do |c, i|
      c.pop
      p =  c[(c.size - 1)].node
      case p.controller
      when 'sections'
        c.concat Pref::Section.find_by_group_id(creator.group.id).bread_crumbs([[]], {:uri => p.public_uri})[0]
      when 'attributes'
        c.concat attribute.bread_crumbs([[]], {:uri => p.public_uri})[0]
      when 'areas'
        if areas.size == 0
          crumbs.delete_at(i)
        else
          tmp = []
          areas.each {|area| tmp << make_crumb.call(area, {:uri => p.public_uri})}
          c << tmp
        end
      when 'categories'
        tmp = []
        categories.each {|cate| tmp << make_crumb.call(cate, {:uri => p.public_uri})}
        c << tmp
      end if p.content.module == 'pref'
    end
    
    crumbs
  end
  
  def search(params)
    params.each do |n, v|
      next if v.to_s == ''
      
      case n
      when 's_attribute_id'
        self.and :attribute_id, v
      when 's_city_id'
        self.and :city_id, v
      when 's_keyword'
        search_keyword v, :title, :body
      end
    end if params.size != 0
    
    return self
  end
end