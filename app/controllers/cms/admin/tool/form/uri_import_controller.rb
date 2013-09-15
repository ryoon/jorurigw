class Cms::Admin::Tool::Form::UriImportController < ApplicationController
  def index
    self.class.layout 'empty'
    @content = nil
    
    return true if params[:elm].to_s == ''
    return true if params[:uri].to_s == '' || params[:uri].to_s == 'http://'
    
    @uri = params[:uri]
    @elm = params[:elm]
    
    res = request_uri(params[:uri])
    return true if res[:status] != 200
    
    @content = NKF::nkf('-w', res[:content])
    @content = @content.gsub(/.*<body.*?>(.*?)<\/body.*/im, '\1')
  end
  
  def request_uri(uri)
    status  = nil
    content = ''
    
    require 'open-uri'
    begin
      open(uri) do |f|
        status = f.status[0].to_i
        f.each_line {|line| content += line}
      end
    rescue
      status = 404
    end
    return {:status => status, :content => content}
  end
end
