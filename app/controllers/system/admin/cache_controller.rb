class System::Admin::CacheController < ApplicationController
  include System::Controller::Scaffold

  def index

  end

  def flush
    CACHE.flush_all
  end

end
