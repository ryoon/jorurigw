class Core
  def self.context
    JoruriContext[self.name] ||= {}
  end
  
  def self.now; context[:now]; end; def self.now=(v); context[:now] = v; end
  
  def self.upload_path
    return File.join(Rails.root, 'upload')
  end
  
  def self.publish_path
    return File.join(Rails.root, 'public')
  end
end