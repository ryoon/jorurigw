class Util::Http::Request
  def send(uri)
    require 'open-uri'

    status  = nil
    body    = ''

    proxy = Site.proxy
    if uri =~ /[a-z]+:\/\/#{Site.domain}/
      proxy = false
    end

    begin
      open(uri, :proxy => proxy) do |f|
        status = f.status[0].to_i
        f.each_line {|line| body += line}
      end
    rescue
      status = 404
    end
    return {:status => status, :body => body}
  end
end