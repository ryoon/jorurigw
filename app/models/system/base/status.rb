class System::Base::Status < PassiveRecord::Base

  schema :id => String, :name => String

  create :disabled,       :name => '無効'
  create :enabled,        :name => '有効'
  create :visible,        :name => '表示'
  create :hidden,         :name => '非表示'
  create :draft,          :name => '下書き'
  create :recognize,      :name => '承認待ち'
  create :recognized,     :name => '公開待ち'
  create :public,         :name => '公開中'
  create :closed,         :name => '非公開'
  create :completed,      :name => '完了'

  def to_xml(options = {})
    options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])

    _root = options[:root] || 'status'

    xml = options[:builder]
    xml.tag!(_root) { |n|
      n.id   key.to_s
      n.name name.to_s
    }
  end
end