class System::Admin::RebootController < ApplicationController
  def index
    f = File.open(File.join(RAILS_ROOT, 'tmp/restart.txt'), 'w')
    f.close
    render :action => 'index', :layout => 'empty'
  end
end
