class Cms::Tool::FeedsController < ApplicationController
  def read
    @skip_layout = true
    
    error = Proc.new do |message|
      render :text => "<xml><errors><error>#{message}</error></errors></xml>" 
    end
    
    return error.call('') if params[:feed].to_s == ''
    
    res = request_uri(params[:feed])
    
    dump res[:status]
    return error.call('') if res[:status] != 200
    
    render :xml => res[:content]
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
