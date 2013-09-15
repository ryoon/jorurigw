class Cms::Admin::Tool::Form::FileImportController < ApplicationController
  def index
    self.class.layout 'empty'
    
    @content = nil
    
    return true unless params[:item]
    return true if params[:elm].to_s == ''
    return true if params[:item][:file] == ''
    
    @elm = params[:elm]
    
#    dump params[:item][:file].original_filename
#    dump params[:item][:file].content_type
#    dump params[:item][:file].size
    
    @content = params[:item][:file].read
    @content = NKF::nkf('-w', @content)
    @content = @content.gsub(/.*<body.*?>(.*?)<\/body.*/im, '\1')
  end
end
