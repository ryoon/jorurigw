class Util::FileLock
  @locked = {}
  
  def self.lock_by_name(name)
    dir  = RAILS_ROOT + '/tmp/lock'
    FileUtils.mkdir(dir) unless File.exists?(dir)
    return false unless f = File.open(dir + '/_' + name, 'w')
    return false unless f.flock(File::LOCK_EX)
    return @locked[name] = f
  end
  
  def self.unlock_by_name(name)
    @locked[name].flock(File::LOCK_UN)
    @locked[name].close
    @locked.delete(name)
    File.unlink(RAILS_ROOT + '/tmp/lock/_' + name)
  end
end