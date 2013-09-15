module Pref::Model::Doc::Category
  def self.included(mod)
    mod.has_many :categories, :primary_key => 'id', :foreign_key => 'doc_id', :class_name => 'Pref::DocCategory',
      :dependent => :destroy

    mod.after_validation :validate_doc_categories
    mod.after_save :save_doc_categories
  end

  attr_accessor :_categories

  def find_doc_category_by_name(name)
    return nil unless categories
    categories.each do |cate|
      return cate.category_id if cate.name == name.to_s
    end
    return nil
  end

  def validate_doc_categories
    exist = nil
    dup   = nil

    if _categories
      tmp = {}
      _categories.each do |k, v|
        exist  = true if v != ''
        dup    = true if v != '' && tmp.has_key?(v)
        tmp[v] = true
      end

      if !exist
        errors.add '分野', 'を選択してください'
      elsif dup
        errors.add '分野', 'が重複しています'
      end
    end
  end

  def save_doc_categories
    return true  unless _categories
    return false unless id
    return false if @save_doc_category_callback_flag

    @save_doc_category_callback_flag = true

    _categories.each do |k, category_id|
      name  = k.to_s

      if category_id == ''
        categories.each do |cate|
          cate.destroy if cate.name == name
        end
      else
        cates = []
        categories.each do |cate|
          if cate.name == name
            cates << cate
          end
        end

        if cates.size > 1
          cates.each {|cate| cate.destroy}
          cates = []
        end

        if cates.size == 0
          cate = Pref::DocCategory.new
          cate.doc_id      = id
          cate.content_id  = content_id
          cate.name        = name
          cate.category_id = category_id
          cate.save
        else
          cates[0].category_id = category_id
          cates[0].save
        end
      end
    end

    categories(true)
    return true
  end
end