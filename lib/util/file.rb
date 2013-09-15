class Util::File
  def self.put(path, options ={})
    if options[:mkdir] == true
      dir = File.dirname(path)
      FileUtils.mkdir_p(dir) unless FileTest.exist?(dir)
    end

    if options[:data]
      f = File.open(path, 'w')
      f.flock(File::LOCK_EX)
      f.puts(options[:data] ? options[:data] : '')
      f.flock(File::LOCK_UN)
      f.close
    elsif options[:src]
      FileUtils.cp options[:src], path
    end

    return true
  end

  def self.rmdir(dir)
    begin
      return Dir.rmdir(dir)
    rescue
      return false
    end
  end

  def self.remove_file(path)
    return true unless FileTest.exist?(path)
    return File.delete(path)
  end
end