class Cms::Admin::Tool::TmpFilesController < ApplicationController
  def index
    self.class.layout 'empty'
    
    dump params
  end
end
