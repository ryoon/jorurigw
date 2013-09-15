class Gw::IndPortalPiece < Gw::Database

  include System::Model::Base
  include System::Model::Base::Config
  include Cms::Model::Base::Content

  validates_presence_of :name, :title
  validate :validate_uniqueness_of_piece

  PIECES = [
    {:name=>'ツール/リマインダー', :title=>'リマインダー', :piece=>'gw-reminder',        :genre=>'tool', :tid=>0, :limit=>5, :position=>'main'},
    {:name=>'ツール/記事更新情報', :title=>'記事更新情報', :piece=>'gw-bbs-syntheses',   :genre=>'tool', :tid=>0, :limit=>5, :position=>'main'},
    {:name=>'ツール/RSS',          :title=>'RSS',          :piece=>'gw-rss-readers',     :genre=>'tool', :tid=>0, :limit=>5, :position=>'main'},
    {:name=>'ツール/メモ帳',       :title=>'メモ帳',       :piece=>'gw-notes',           :genre=>'tool', :tid=>0, :limit=>5, :position=>'main'},
    {:name=>'ツール/リンクピース', :title=>'リンクピース', :piece=>'gw-ind-link-pieces', :genre=>'tool', :tid=>0, :limit=>5, :position=>'left'},
    {:name=>'ツール/ブログパーツ', :title=>'ブログパーツ', :piece=>'gw-blog-parts',      :genre=>'tool', :tid=>0, :limit=>5, :position=>'left'}
  ]

  def validate_uniqueness_of_piece
    cond = "uid=#{self.uid}"
    items = self.find(:all, :conditions => cond)
    for item in items
      if item.piece == self.piece && item.genre == self.genre && item.tid == self.tid && item.id != self.id
        self.errors.add(:name, "はすでに登録されています。")
        return false
      end
    end
    return true
  end

  def set_default
    self.uid = Site.user.id
    self.sort_no = Gw::IndPortalPiece.next_sort_no
    self.title = ""
    self.limit = 5
  end

  def board_piece?
    return true if self.piece == 'gw-bbs-mock'
    return false
  end

  def piece_name
    return "piece/#{self.piece} #{self.genre}_#{self.tid}_#{self.limit}" if self.board_piece?
    return "piece/#{self.piece}"
  end

  def piece_name_for_select
    return [self.piece, self.genre, self.tid].join(" ")
  end

  def get_limit_str
    return self.limit.to_s if self.board_piece?
    return "-"
  end

  def get_link_str
    return "/#{self.genre}/docs?title_id=#{self.tid}" if self.board_piece?
    return ""
  end

  def self.get_user_items
    cond = "uid = #{Site.user.id}"
    order = "sort_no"
    items = self.find(:all, :order => order, :conditions => cond)
    if items.blank?
      items = self.create_default_user_items
    end
    return items
  end

  def self.get_usable_items
    items = []

    items += self.get_board_system_items('gwbbs')
    items += self.get_board_system_items('gwfaq')
    items += self.get_board_system_items('gwqa')
    items += self.get_board_system_items('doclibrary')
    items += self.get_board_system_items('digitallibrary')

    items += self.get_non_board_system_items
    return items
  end

  def self.get_user_cand_items(position=nil)
    user_items = self.get_user_items
    cand_items = self.get_usable_items
    user_items.each do |x|
      cand_items.reject! do |y|
        y.piece_name_for_select == x.piece_name_for_select
      end
    end
    if position
      user_items = user_items.select { |x| x.position == position }
      cand_items = cand_items.select { |x| x.position == position }
    end
    return user_items, cand_items
  end

  def self.get_user_cand_items_with(ex_item, position=nil)
    user_items = self.get_user_items
    cand_items = self.get_usable_items
    user_items.each do |x|
      cand_items.reject! do |y|
        y.piece_name_for_select == x.piece_name_for_select && x.id != ex_item.id
      end
    end
    if position
      user_items = user_items.select { |x| x.position == position }
      cand_items = cand_items.select { |x| x.position == position }
    end
    return user_items, cand_items
  end

  def self.next_sort_no
    item = self.find(:first, :order => "sort_no DESC", :conditions => "uid = #{Site.user.id}")
    if item.blank?
      max = 0
    else
      max = item.sort_no
    end
    return max + 10
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

  def self.piece_select_list(items)
    list = [["", ""]]
    items.each do |item|
      list << [item.name, item.piece_name_for_select]
    end
    return list
  end

  def self.limit_select_list
    list = []
    1.step(20, 1) do |i|
      list << [i,i]
    end
    return list
  end

protected

  def self.create_default_user_items
    items = self.get_default_user_items
    begin
      transaction do
        items.each do |item|
          item.save!
        end
      end
    rescue => e
      case e.class.to_s
        when 'ActiveRecord::RecordInvalid', 'Gw::ARTransError'
      else raise e
      end
    end
    return items
  end

  def self.get_default_user_items

    items = self.create_user_items_from_properties
    unless items.blank?

      Gw::Model::UserProperty.save('portal', {:portals=>{}})
      return items
    end

    items = []
    hashes = Gw::NameValue.get_cache('yaml', nil, 'gw_ind_portal_pieces_system_default').values.sort{|a,b| a['sort_no'] <=> b['sort_no']}
    hashes.each do |hash|
      item = self.new(hash)
      item.uid = Site.user.id
      items << item
    end
    return items
  end

  def self.create_user_items_from_properties
    items = []

    pieces = Gw::Model::Schedule.get_settings('portals').values.sort{|a,b| a['sort_no']<=>b['sort_no']}

    usable_items = self.get_usable_items

    pieces.each do |piece|
      newitem = self.create_from_properties(piece, usable_items)
      items << newitem unless newitem.blank?
    end
    if items.length != 0

      if items.select{|x| x.piece == 'gw-ind-link-pieces'}.length == 0
        linkitem = usable_items.select{|x| x.piece == 'gw-ind-link-pieces'}
        if linkitem.length == 1
          newitem = self.new(linkitem[0].attributes)
          newitem.uid = Site.user.id
          items << newitem
        end
      end
    end

    items.each_with_index do |item, idx|
      item.sort_no = (idx+1)*10
    end
    return items
  end

  def self.create_from_properties(hash, usable_items)
    item = nil
    if hash['piece_name']
      piece_data = hash['piece_name'].gsub!(/^piece\//, '').split(/ /)
      if piece_data.length == 2
        piece = piece_data[0]
        genre, tid, limit = piece_data[1].split(/_/)
      elsif piece_data.length == 1
        piece = piece_data[0]
      end

      if piece =~ /^gw-bbs-mock/
        selected_items = usable_items.select{|x| x.piece==piece && x.genre==genre && x.tid==tid.to_i}
        if selected_items.length == 1
          item = self.new(selected_items[0].attributes)
          item.uid = Site.user.id
          item.limit = limit.to_i
        end

      else
        selected_items = usable_items.select{|x| x.piece==piece && x.genre=='tool' }
        if selected_items.length == 1
          item = self.new(selected_items[0].attributes)
          item.uid = Site.user.id
        end
      end
    end
    return item
  end

  def self.get_genre_string(genre)
    str = ""
    case genre
      when 'gwbbs'
      str = '掲示板'
      when 'gwfaq'
      str = '質問管理'
      when 'gwqa'
      str = '質問管理'
      when 'doclibrary'
      str = '書庫'
      when 'digitallibrary'
      str = '電子図書'
    end
    return str
  end

  def self.get_board_system_items(genre)
    items = []
    cands = Gw::Tool::Board.get_titles(genre)
    cands.each do |cand|
      if Gw::Tool::Board.readable_board?(genre, cand.id)
        item = self.new
        item.uid = Site.user.id
        item.name = "#{get_genre_string(genre)}/#{cand.title}"
        item.title = cand.title
        item.piece = 'gw-bbs-mock'
        item.tid = cand.id
        item.genre = genre
        item.limit = 10
        item.position = 'main'
        items << item
      end
    end
    return items
  end

  def self.get_non_board_system_items
    items = []
    PIECES.each do |piece|
      item = self.new(piece)
      item.uid = Site.user.id
      items << item
    end
    return items
  end
end