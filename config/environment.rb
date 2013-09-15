$KCODE = 'u'
require 'jcode'

# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.4' unless defined? RAILS_GEM_VERSION

# グローバル定数定義
# 公開画面ログオンを利用する場合 1
PUBLIC_LOGIN = 1
# public の dispatch トレースを行う場合 1
PUBLIC_TRACE_LOG = 0
# public の view のフルパス表示を行う場合 1
PUBLIC_SHOW_PATH = 0
# public で piece が見つからない表示を行う場合 1
PUBLIC_SHOW_PIECE_NOT_FOUND = 0
# pages(contents) から piece の呼び出しを許可
ENABLE_PIECE_IN_CONTENT = 1
# piece から directive の呼び出しを許可
ENABLE_DIRECTIVE_IN_PIECE = 1
# pages から directive の呼び出しを許可
ENABLE_DIRECTIVE_IN_CONTENT = 1
## 組織関連
#LDAP有無　0:無、1:有
GW_USE_LDAP = 1
#組織階層上限
GW_GROUP_MAX_LEVEL = 3
#組織階層毎のコード長（[level,length]、固定長、前ゼロを付ける）
GW_GROUP_CODE_LENGTH = [1,3,6]

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  #config.gem 'activeldap', :lib => 'active_ldap', :version => "1.2.0"
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Specify gems that this application depends on and have them installed with rake gems:install
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "sqlite3-ruby", :lib => "sqlite3"
  # config.gem "aws-s3", :lib => "aws/s3"

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  #config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
  config.i18n.default_locale = 'ja'

  # logging.
  #config.log_level = :info

  #config.logger = Logger.new("#{RAILS_ROOT}/log/#{RAILS_ENV}.log")
  #config.logger.datetime_format = "%Y-%m-%dT%H:%M:%S.%06d"
  #config.logger.formatter = Logger::Formatter.new
  config.active_record.colorize_logging = false
end

require 'pp'
module Kernel
  private
  def pp(*objs)
    logger = Logger.new File.join(RAILS_ROOT, 'log', 'out.log')
    objs.each { |obj| logger.debug PP.pp(obj, '') }
    nil
  end
  def pp_common(logfile, *objs)
    logger = Logger.new File.join(RAILS_ROOT, 'log', logfile)
    objs.each { |obj| logger.debug PP.pp(obj, '') }
    nil
  end
  def pp_public_dispatch_log(*objs)
    return unless PUBLIC_TRACE_LOG == 1
    pp_common 'public_dispatch.log', {"time" => Time.now }, objs
  end
end

def nz(value, valueifnull='')
  value.blank? ? valueifnull : value
end
def nf(value, valueifnull='')
  # no-falsy, falsy: false, nil, '', 0, '0'
  value.blank? || value.to_s == '0' ? valueifnull : value
end

CalendarDateSelect.format = :db

ENV['STRING_ENCRYPTION_KEY'] = "b04f36864a2f068499df535fbf37"


#memcached
require 'memcache'
memcache_options = {
    :c_threshold => 10_000,
    :compression => true,
    :debug => false,
    :namespace => ":joruri-gw-#{RAILS_ENV}",
    :readonly => false,
    :urlencode => false
}
CACHE = MemCache.new memcache_options
CACHE.servers = 'localhost:11211'




