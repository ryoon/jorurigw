class Questionnaire::Base::QuestionType < PassiveRecord::Base

  schema :id => String, :value => String, :name => String, :max_length => Integer

  create :text,       :value =>'text',        :name => 'テキストボックス',     :max_length => 100
  create :textarea,   :value =>'textarea',    :name => 'テキストエリア',       :max_length => 500
  create :radio,      :value =>'radio',       :name => 'ラジオボタン',         :max_length => -1
  create :checkbox,   :value =>'checkbox',    :name => 'チェックボックス',     :max_length => -1
  create :select,     :value =>'select',      :name => 'セレクトボックス',     :max_length => -1
  create :display,    :value =>'display',     :name => 'ラベルテキスト',       :max_length => -1
  create :group,      :value =>'group',       :name => 'グループ設定',         :max_length => -1


  def self.sort_by_value
    sorted_arr = ['text', 'textarea', 'radio', 'checkbox', 'select', 'display', 'group']
    result = []
    for val in sorted_arr
      result << self.find_by_value(val)
    end
    return result
  end

end