class Gwboard::Public::SiteinfoController < ApplicationController
  include Gwboard::Controller::Scaffold

  def initialize_scaffold
    @css = ["/_common/themes/gw/css/bbs.css"]
  end

  def index
    rails_env = ENV['RAILS_ENV']
    begin
      site = YAML.load_file('config/site.yml')
      @host = site[rails_env]['host']
    rescue
    end
  end
end