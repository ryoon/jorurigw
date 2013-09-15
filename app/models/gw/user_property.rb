class Gw::UserProperty < Gw::Database
  include System::Model::Base

  def is_email_mobile?
    return false if self.options.blank? || self.name != 'mobile'

    options = JsonParser.new.parse(self.options)
    if !options['mobiles'].blank? && !options['mobiles']['kmail'].blank? && !options['mobiles']['ktrans'].blank?
      if options['mobiles']['ktrans'] == '1' && Gw::MemoMobile.is_email_mobile?(options['mobiles']['kmail'])
        return true
      end
    end
    return false

  end

  def self.is_todos_display?

    todos_display = false
    todo_settings = Gw::Model::Schedule.get_settings 'todos', {}
    if todo_settings.key?(:todos_display_schedule)
      todos_display = true if todo_settings[:todos_display_schedule].to_s == '1'
    end
    return todos_display
  end
end
