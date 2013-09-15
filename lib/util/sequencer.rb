class Util::Sequencer
  def self.next_id(name, version = 0)

    lock_name = name.to_s + version.to_s
    unless Util::FileLock.lock_by_name(lock_name)
      raise "error: sequencer locked"
    end

    if seq = System::Sequence.versioned(version).find_by_name(name)
      seq.value += 1
      seq.save
    else
      seq = System::Sequence.new
      seq.name = name
      seq.version = version
      seq.value = 1
      seq.save
    end

    Util::FileLock.unlock_by_name(lock_name)
    return seq.value
  end
end