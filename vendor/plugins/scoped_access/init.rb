ActionController::Base.instance_eval do
  def scoped_access (*args, &block)
    options = (Hash === args.last && !(args.last.keys & [:only, :except]).empty?) ? args.pop : {}
    send(:around_filter, ScopedAccess::Filter.new(*args, &block), options)
  end
end

require 'dispatcher'
class ::Dispatcher
  app = respond_to?(:prepare_application, true) ? (class << self; self end) : self
  app.class_eval do
    private
    def prepare_application_with_reset
      ScopedAccess.reset
#-      prepare_application_without_reset
    end

#-    alias_method :prepare_application_without_reset, :prepare_application
#-    alias_method :prepare_application, :prepare_application_with_reset
#+
     before_dispatch :prepare_application_with_reset
  end
end

ActiveRecord::Base.instance_eval do
  def reset_scope
    scoped_methods.clear
  end
end
