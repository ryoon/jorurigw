class Content

  def self.context
    JoruriContext[self.name] ||= {}
  end

  def self.node; context[:node]; end; def self.node=(v); context[:node] = v; end
  def self.current; context[:current]; end; def self.current=(v); context[:current] = v; end
  def self.site; context[:site]; end; def self.site=(v); context[:site] = v; end

  attr_accessor :path
  attr_accessor :internal_path

  def initialize(path)
    node    = nil
    current = nil
    site    = nil

    @path          = path.gsub(/#.*/, '')
    @internal_path = @path

  end

  def initialize_content(path)
    rest = ''
    paths = path.split('/')
    paths[0] = '/'
    paths.size.times do |i|
      next if paths[i] == ''
      _node = Cms::Node.new.public
      _node.parent_id = self.class.context[:node] ? self.class.context[:node].id : 0
      _node.name = paths[i]
      break unless tmp = _node.find(:first)
      self.class.context[:site] = tmp unless self.class.context[:node]
      self.class.context[:node] = tmp
      rest = paths.slice(i + 1, paths.size).join('/')
    end
    unless self.class.context[:node]
      return @internal_path = false
    end

    if self.class.context[:node].content
      self.class.context[:current] = self.class.context[:node].content
      @internal_path = File.join('/_public', self.class.context[:current].module, self.class.context[:node].controller, rest)
    else
      @internal_path = File.join('/_public', 'cms', self.class.context[:node].controller, rest)
    end
  end
end