class Cms::Admin::Tool::Form::LinkCheckController < ApplicationController
  def index
    self.class.layout 'empty'
    @body = ''
    @urls = {}
    @imgs = []
    
    return true unless params[:item]
    return true unless name = params[:name]
    
    @body = params[:item][name]
    
    #/https?:\/\/[-_.!~*'()a-zA-Z0-9;\/?:@&=+$,%#]+/
    @body.scan(/href="(.*?)"/i).each do |url|
      url = url[0]
      url = Site.uri(:http => true) + url.slice(1, url.size) if url.slice(0, 1) == '/'
      @urls[url] = request_url(url) unless @urls[url]
    end
    
    @body.scan(/<img (.*?)>/i).each do |img|
      attr = img[0]
      res = attr =~ /alt=".+?"/i ? true : false
      @imgs << ["<img #{attr}>", res]
    end
  end
  
  def request_url(url)
    status = nil
    
    require 'open-uri'
    begin
      open(url) do |f|
        status = f.status[0]
      end
    rescue
      status = 404
    end
    return status == '200'
  end
end
