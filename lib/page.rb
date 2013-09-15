class Page
  def self.context
    JoruriContext[self.name] ||= {}
  end
  def self.css_id; context[:css_id]; end; def self.css_id=(v); context[:css_id] = v; end
  def self.error; context[:error]; end; def self.error=(v); context[:error] = v; end
  def self.title; context[:title]; end; def self.title=(v); context[:title] = v; end
  def self.layout; context[:layout]; end; def self.layout=(v); context[:layout] = v; end

  def self.css_id
    id = Site.request_path
    id += 'index.html' if /\/$/ =~ id
    id = id.slice(1, id.size)
    id = id.gsub(/\..*$/, '')
    id = id.gsub(/\.[0-9a-zA-Z]+$/, '')
    id = id.gsub(/[^0-9a-zA-Z_\.\/]/, '_')
    id = id.gsub(/(\.|\/)/, '-').camelize(:lower)
    return 'page-' + id
  end

  def self.title
    return context[:title] if context[:title]
    return Site.current_node.title if Site.current_node
    return Site.title
  end

  def self.window_title
    return title if title == Site.title
    return title + ' - ' + Site.title
  end
end