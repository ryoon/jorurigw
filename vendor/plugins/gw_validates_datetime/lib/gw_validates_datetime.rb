# validate_email_format_of をベースに作成
module ActiveRecord
  module Validations
    module ClassMethods
      # Validates whether the value of the specified attribute is a valid email address
      #   class User < ActiveRecord::Base
      #     validates_email_format_of :email, :on => :create
      #   end
      # Configuration options:
      # * <tt>message</tt> - A custom error message (default is: " does not appear to be a valid e-mail address")
      # * <tt>on</tt> - Specifies when this validation is active (default is :save, other options :create, :update)
      # * <tt>allow_nil</tt> - Allow nil values (default is false)
      # * <tt>allow_blank</tt> - Allow blank values (default is false)
      # * <tt>if</tt> - Specifies a method, proc or string to call to determine if the validation should
      #   occur (e.g. :if => :allow_validation, or :if => Proc.new { |user| user.signup_step > 2 }).  The
      #   method, proc or string should return or evaluate to a true or false value.
      # * <tt>unless</tt> - See <tt>:if</tt>
      def gw_validates_datetime(*attr_names)
        require 'parsedate'
        options = { :message => ActiveRecord::Errors.default_error_messages[:datetime],
                          :on => :save,
                          :allow_nil => false,
                          :allow_blank => false }
        # options.update(attr_names.pop) if attr_names.last.is_a?(Hash)
        user_options  = attr_names.extract_options!
        allow_nil     = user_options.delete(:allow_nil)
        allow_blank   = user_options.delete(:allow_blank)
        options.update(user_options)
        validates_each(attr_names, options) do |record, attr_name, value|
          # 型キャスト済だと具合悪いので回避
          # "codeなにがし::キャスト前の値を検証する validates_format_of":http://code.nanigac.com/source/view/586
          debug = nil # debug = 1
          v = Gw.trim(record.attributes_before_type_cast[attr_name.to_s])
          pp [:v, v] if debug
          next if ((allow_nil && v.nil?) || (allow_blank && v.blank?))
          # exact
          if options[:loose].blank? && (/^\d{4}[\-\/]\d{1,2}[\-\/]\d{1,2}( +\d{1,2}\:\d{1,2}(:\d{1,2})?)?$/ !~ v)
            pp :r1 if debug
            record.errors.add(attr_name, options[:message] % value)
            next
          end
          w1 = ParseDate::parsedate(v)
          pp [:w1, w1] if debug
          #w1[0] = Time.now.year if w1[0].nil?
          #errors_count_bak = record.errors.length
          flg_date_exist = (w1[0].nil? || w1[1].nil? || w1[2].nil?) ? false : Date.exist?(w1[0], w1[1], w1[2]).nil?
          flg_time_range = (!w1[3].nil? && w1[3] > 23) || (!w1[4].nil? && w1[4] > 59)
          case
          when !w1[0].nil? && !w1[1].nil? && !w1[2].nil? && !w1[3].nil? && !w1[4].nil?
            # 日時
            pp :r2 if debug
            record.errors.add(attr_name, options[:message] % value) if flg_date_exist || flg_time_range
          when !w1[0].nil? && !w1[1].nil? && !w1[2].nil? && w1[3].nil? && w1[4].nil? && w1[5].nil?
            # 日付
            pp :r3 if debug
            record.errors.add(attr_name, options[:message] % value) if flg_date_exist
          when w1[0].nil? && w1[1].nil? && w1[2].nil? && !w1[3].nil? && !w1[4].nil?
            # 時刻
            pp :r4 if debug
            record.errors.add(attr_name, options[:message] % value) if flg_time_range
          else
            pp :r5 if debug
            record.errors.add(attr_name, options[:message] % value)
          end
          #pp 'ok' if errors_count_bak == record.errors.length
        end
      end
      def validates_unlike(*attr_names)
        # "Rails - validates_unlike plugin : validate that an attribute doesn’t match against a RegExp ?? La Cara Oscura del Desarrollo de Software":http://www.lacaraoscura.com/2006/07/11/validates-unlike-plugin/
        configuration = { :message => ActiveRecord::Errors.default_error_messages[:invalid], :on => :save, :with => nil }
        configuration.update(attr_names.pop) if attr_names.last.is_a?(Hash)

        raise(ArgumentError, "A regular expression must be supplied as the :with option of the configuration hash") unless configuration[:with].is_a?(Regexp)

        validates_each(attr_names, configuration) do |record, attr_name, value|
          record.errors.add(attr_name, configuration[:message]) if value.to_s =~ configuration[:with]
        end
      end
      def validates_unlike_hankana(*attr_names)
        configuration = { :message => ActiveRecord::Errors.default_error_messages[:invalid], :on => :save }
        configuration.update(attr_names.pop) if attr_names.last.is_a?(Hash)

        validates_each(attr_names, configuration) do |record, attr_name, value|
          record.errors.add(attr_name, configuration[:message]) if value.to_s =~ get_utf8_hankana_regexp
        end
      end
      def get_utf8_hankana_regexp
        /(?:\xEF\xBD[\xA1-\xBF]|\xEF\xBE[\x80-\x9F])/
      end
    end
  end
end
