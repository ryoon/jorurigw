class Util::Config
  @@cache = {}
  
  def self.load(filename, attribute = nil)
    yml = self.read(filename)
    return yml unless attribute
    return yml[attribute]
  end
  
private
  def self.read(filename)
    unless @@cache[filename]
      config = File.join(RAILS_ROOT, 'config', filename + '.yml')
      @@cache[filename] = YAML.load_file(config)[Rails.env]
    end
    return @@cache[filename]
  end
  
end
