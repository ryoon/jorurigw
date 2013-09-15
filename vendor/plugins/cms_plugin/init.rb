require 'cms_dump'
require 'cms_plugin'
require 'joruri_context'
require 'site'

#module ActionController
#  module Routing
#    class RouteSet
#      def recognize_path(path, environment={})
#        site = Site.initialize(path)
#        path = Site.internal_path
#        dump '# ' + path
#        
#        super(path, environment)
#      end
#    end
#  end
#end

ActionController::Routing::Routes.instance_eval do
  def logger
    @logger ||= RAILS_DEFAULT_LOGGER
  end
  
  def recognize_path(path, environment={})
    # clear context.
    JoruriContext.clear
    
    site = Site.initialize(path)
    path = Site.internal_path
    logger.debug { "internal_path: #{path}" }
    #dump '# ' + path
    
    super(path, environment)
  end
  
  #def recognize(request)
  #  super(request)
  #end
end

#::Dispatcher.instance_eval do
#  def initialize(output = $stdout, request = nil, response = nil)
#    @output = output
#    @app = @@middleware.build(lambda { |env| self.dup._call(env) })
#  end
# 
#  def dispatch(cgi = nil, session_options = CgiRequest::DEFAULT_SESSION_OPTIONS, output = $stdout)
#    new(output).dispatch_cgi(cgi, session_options)
#  end
#end
