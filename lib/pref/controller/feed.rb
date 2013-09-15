module Pref::Controller::Feed
  def render_feed(items)
    case params[:format]
    when 'rss'
      @skip_layout = true
      return render(:xml => to_rss(items))
    when 'atom'
      @skip_layout = true
      return render(:xml => to_atom(items))
    else
      return false
    end
  end

  def to_rss(entries)
    base_uri = Site.uri(:http => true).gsub(/\/$/, '')

    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.rss('version' => '2.0') do
      xml.channel do
        xml.title       Page.title + ' - ' + Site.title
        xml.link        base_uri + Site.request_uri
        xml.language    "ja"
        xml.description Page.title

        entries.each do |entry|
          xml.item do
            xml.title        entry.title
            xml.link         base_uri + entry.public_uri
            xml.description  entry.body
            xml.pubDate      entry.published_at.rfc822
          end
        end
      end
    end
  end

  def to_atom(entries)
    base_uri = Site.uri(:http => true).gsub(/\/$/, '')

    xml = Builder::XmlMarkup.new
    xml.instruct! :xml, :version => 1.0, :encoding => 'UTF-8'
    xml.feed 'xmlns' => 'http://www.w3.org/2005/Atom' do
      xml.title   Page.title + ' - ' + Site.title
      xml.link    :rel => 'alternate', :href => base_uri + Site.request_uri
      xml.link    :rel => 'self', :href => base_uri
      xml.updated Time.now.rfc822
      xml.author  Site.title

      entries.each do |entry|
        xml.entry do
          xml.title   entry.title
          xml.link    :rel => 'alternate', :href => base_uri + entry.public_uri
          xml.id      base_uri + entry.public_uri
          xml.updated entry.published_at.rfc822
          xml.author  entry.creator.group.name if entry.creator
          xml.summary entry.body
        end
      end
    end
  end
end