class Cache
  $KCODE = "UTF8"
  def self.load(c_key)
    begin
      value = CACHE.get c_key
      dump value
      if value.blank?
        value = yield
      dump "yield：#{value}"
        CACHE.set c_key, value, 300
      else
        Rails.logger.debug('CACHE HIT:' + c_key)
      end
    rescue => e
      value = yield
      dump 'CACHE ERROR:' + c_key
      dump e.backtrace.join("\n")
    end
    return value
  end
end
