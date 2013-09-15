class JoruriContext

  JORURI_CONTEXT_NAME = :_joruri_context

  def self.[](k)
    return nil unless ::Thread.current.key?(JORURI_CONTEXT_NAME)
    context[k]
  end

  def self.[]=(k, v)
    logger.debug { "set thread context. thread=#{Thread.current.inspect}: #{k}=#{v.inspect}" }
    context[k] = v
  end

  def self.delete(k)
    return nil unless ::Thread.current.key?(JORURI_CONTEXT_NAME)
    context.delete(k)
  end

  def self.key?(k)
    return false unless ::Thread.current.key?(JORURI_CONTEXT_NAME)
    context.has_key?(k)
  end

  def self.keys
    return [] unless ::Thread.current.key?(JORURI_CONTEXT_NAME)
    context.keys
  end

  def self.clear
    return unless ::Thread.current.key?(JORURI_CONTEXT_NAME)
    logger.debug { "clear context. thread=#{Thread.current.inspect}" }
    ::Thread.current[JORURI_CONTEXT_NAME] = nil
  end

  private
  def self.context
    unless ::Thread.current.key?(JORURI_CONTEXT_NAME)
      logger.debug { "create context. thread=#{Thread.current.inspect}" }
      ::Thread.current[JORURI_CONTEXT_NAME] = {}
    end
    ::Thread.current[JORURI_CONTEXT_NAME]
  end

  def self.logger
    @@logger ||= RAILS_DEFAULT_LOGGER
  end
end
