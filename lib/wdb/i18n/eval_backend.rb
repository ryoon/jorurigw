class Wdb::I18n::EvalBackend < I18n::Backend::Simple
  MATCH2 = /(\\\\)?\(\(([^\(][^\)]+?)\)\)/

  def interpolate(locale, string, values = {})

    logger = Logger.new(STDOUT)

    return string unless string.is_a?(String)

    if string.respond_to?(:force_encoding)
      original_encoding = string.encoding
      string.force_encoding(Encoding::BINARY)
    end

    result = string.gsub(MATCH) do
      escaped, pattern, key = $1, $2, $2.to_sym

      if escaped
        pattern
      elsif INTERPOLATION_RESERVED_KEYS.include?(pattern)
        raise ::I18n::ReservedInterpolationKey.new(pattern, string)
      elsif !values.include?(key)
        raise ::I18n::MissingInterpolationArgument.new(pattern, string)
      else
        values[key].to_s
      end
    end

    result = result.gsub(MATCH2) do
      escaped, pattern, key = $1, $2, $2.to_sym

      if escaped
        pattern
      elsif INTERPOLATION_RESERVED_KEYS.include?(pattern)
        raise ::I18n::ReservedInterpolationKey.new(pattern, string)
      else

        _names = pattern.split(".")

        first = _names.shift
        if !values.include?(first.to_sym)
          raise ::I18n::MissingInterpolationArgument.new(first, string)
        end
        _obj = values[first.to_sym]

        _names.each do |name|
          next if name.empty?
          _base = _obj
          begin

            _obj = _obj.instance_eval("self.#{name}")
          rescue NameError => e
            logger.warn e
          rescue => e
            logger.warn e
          end
        end
        _obj.to_s
      end
    end

    result.force_encoding(original_encoding) if original_encoding
    result
  end

end
