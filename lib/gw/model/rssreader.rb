class Gw::Model::Rssreader
  TIMEOUT = 3
  def self.get_feeds(feed_id = nil)
    hu = Gw::Model::UserProperty.get('feed')
    return {} if hu.nil?
    feeds = hu['feeds']
    ret = []
    feeds.sort{|a,b|
      a['index'].to_i<=>b['index'].to_i
    }.each do |feed|
      if feed_id.nil? || feed['id'].to_s == feed_id.to_s
        begin
          hx = self.get_hash3(feed['uri'], nz(feed['max'].to_i,0))
        rescue Timeout::Error
          hx = [ 'date' => format_datetime(Time::now.to_s),
            'title' => feed['title'],
            'link' => 'タイムアウト',
            'result' => 0 ]
        rescue => evar
          hx = [ 'date' => format_datetime(Time::now.to_s),
            'title' => feed['title'],
            'link' => '取得失敗',
            'result' => 0 ]
        end
        ret.push({
          'index' => feed['index'],
          'title' => feed['title'],
          'heads' => hx
        })
      end
    end
    return ret
  rescue
    return {} if hu.nil?
  end

  def self.get_hash3(uri, max=0)
    require 'feed-normalizer'
    require 'open-uri'
    rc = Gw::RssCache.find(:all, :conditions=>"uri='#{uri}'", :order=>'published desc')
    fetch_expired_limit_seconds = 3600
    if rc.length == 0
      ret = get_hash_core(uri, max)
    else
      if Time.now - rc.last.fetched > fetch_expired_limit_seconds
        ret = get_hash_core(uri, max)
      else
        ret = rc.slice(0,max) if max > 0
        ret = ret.collect {|x| {
            'date' => format_datetime(x.published),
            'title' => x.title + '[CACHE]',
            'link' => x.link
        }}
      end
    end
    ret
  end

  def self.get_hash_core(uri, max=0)
    require 'feed-normalizer'
    require 'open-uri'
    fetched = Time.now
    f = timeout(TIMEOUT) {
      open(uri).read # ruby file open.
    }
    feed = FeedNormalizer::FeedNormalizer.parse f
    ret = feed.entries.sort{|a,b|b.date_published<=>a.date_published}
    Gw::RssCache.destroy_all("uri='#{uri}'")
    ret.each {|x|
      Gw::RssCache.new({:uri=>uri, :fetched=>fetched, :title=>x.title, :published=>x.date_published, :link=>x.urls[0]}).save
    }
    ret = ret.slice(0,max) if max > 0
    ret = ret.collect {|x| {
        'date' => format_datetime(x.date_published),
        'title' => x.title,
        'link' => x.urls[0]
    }}
    return ret
  end

  def self.get_hash2(uri, max=0)
    require 'feed-normalizer'
    require 'open-uri'
    f = timeout(TIMEOUT) {
      open(uri).read # ruby file open.
    }
    feed = FeedNormalizer::FeedNormalizer.parse f
    ret = feed.entries.sort{|a,b|b.date_published<=>a.date_published}
    ret = ret.slice(0,max) if max > 0
    ret = ret.collect {|x|
      {
        'date' => format_datetime(x.date_published),
        'title' => x.title,
        'link' => x.urls[0]
      }
    }
    return ret
  end

  def self.get_hash(uri, max=0)
    f = timeout(TIMEOUT) {
      open(uri).read # ruby file open.
    }
    hx = Hash.from_xml(f)
    if !hx['RDF'].nil? && nz(hx['RDF']['xmlns'],'') == 'http://purl.org/rss/1.0/' # RSS1.0
      idx=0
      if hx['RDF']['item'].class.to_s == 'Hash' # RSS1.0 で送信データが1件しかない場合、構造が異なるので対応
        hw = hx['RDF']['item']
        hx.delete 'item'
        hx['RDF']['item'] = [hw]
      end
      hx['RDF']['item'].each{|x|
        hx['RDF']['item'][idx]['date'] = format_datetime(hx['RDF']['item'][idx]['date'])
        idx+=1
      }
      hw = hx['RDF']['item'].sort{|a,b| b['date']<=>a['date']}
      hw = hw.slice(0,max) if max > 0
      ret = hw.map {|x|
        { 'date' => x['date'],
          'title' => x['title'],
          'link' => x['rdf:about']}}
    elsif !hx['rss'].nil? && nz(hx['rss']['version'],'') == '2.0' # RSS2.0
      idx=0
      hx['rss']['channel']['item'].each{|x| hx['rss']['channel']['item'][idx]['pubDate'] = format_datetime(hx['rss']['channel']['item'][idx]['pubDate']); idx+=1}
      hw = hx['rss']['channel']['item'].sort{|a,b| b['pubDate']<=>a['pubDate']}
      hw = hw.slice(0,max) if max > 0
      ret = hw.map {|x|
        { 'date' => x['pubDate'],
          'title' => x['title'],
          'link' => x['link'].is_a?(Array) ? x['link'][0] : x['link']}}
    else
      raise TypeError, "unknown feed format"
      ret = nil
    end
    return ret
  end
private
  def self.format_datetime(d)
    format = '%Y-%m-%d %H:%M:%S'
    case d.class.to_s
    when 'DateTime', 'Time'
      d.strftime(format)
    when 'String'
      DateTime.parse(d).strftime(format)
    else
      raise TypeError, "unknown class type"
    end
  end
end