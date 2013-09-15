class Wdb::I18n::ReflectionBackend < I18n::Backend::Simple
  MATCH2 = /(\\\\)?\(\(([^\(][^\)]+?)\)\)/

  def interpolate(locale, string, values = {})
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

          if _obj.is_a?(ActiveRecord::Base) || _obj.is_a?(PassiveRecord::Base)
            _base = _obj
            _obj = _obj.read_attribute(name)
            unless _obj
              if _base.class.reflections.has_key?(name.to_sym)
                _obj = _base.send(name)
              else
                #
              end
            end
          elsif _obj.instance_variables.detect(nil){|v| v == "@#{name}" }
            _obj = _obj.instance_variable_get("@#{name}")
          else
            _obj = "??#{pattern}??"
            break
          end
        end
        _obj.to_s
      end
    end

    result.force_encoding(original_encoding) if original_encoding

    result
  end

end
