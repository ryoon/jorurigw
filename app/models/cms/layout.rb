class Cms::Layout < ActiveRecord::Base
#  acts_as_cached
  include System::Model::Base
  include System::Model::Base::Content
  include System::Model::Unid
  include System::Model::Unid::Creator
  #include System::Model::Unid::Recognition
  include System::Model::Unid::Publication
  include System::Model::Unid::Commitment

  belongs_to :status,  :foreign_key => :state,      :class_name => 'System::Base::Status'

  validates_presence_of :state, :name, :title, :body

  def states
    {'public' => '公開'}
  end

  def head_tag(mobile = false, smartphone = false)
    _tag = ""
    if mobile == true
      if smartphone == true
        _tag += self.s_mobile_head if self.s_mobile_head
        _tag += %Q(<meta name="viewport" content="width=device-width,minimum-scale=1.0,maximum-scale=1.0,user-scalable=no"/>\n)
      else
        _tag += self.mobile_head if self.mobile_head
      end
      _css = File.join(Site.uri, 'layout', name, 'mobile.css')
      _tag += '<link rel="stylesheet" type="text/css" href="' + _css + '" />' + "\n"
    else
      _css = File.join(Site.uri, 'layout', name, 'style.css')
      _tag = '<link rel="stylesheet" type="text/css" href="' + _css + '" />' + "\n"
      _tag += self.head if self.head
    end

    _tag
  end

  def publishable? # TODO dummy
    return true
  end

  def public_uri # TODO dummy
    '/layout/' + name + '/style.css'
  end

  def request_publish_data # TODO dummy
    _res = {
      :page_type => 'text/css',
      :page_size => stylesheet.size,
      :page_data => stylesheet,
    }
  end

  def tamtam_css
    css = ''
    _css = '/layout/' + name + '/mobile.css'
    css += %Q(@import "#{_css}";\n)
    unless mobile_head.blank?
      mobile_head_tag = _tag + mobile_head
      mobile_head_tag.scan(/<link [^>]*?rel="stylesheet"[^>]*?>/i) do |m|
        css += %Q(@import "#{m.gsub(/.*href="(.*?)".*/, '\1')}";\n)
      end
    end

    css += mobile_stylesheet if !mobile_stylesheet.blank?

    4.times do
      css = convert_css_for_tamtam(css)
    end
    css.gsub!(/^@.*/, '')
    css.gsub!(/[a-z]:after/i, '-after')
    css
  end
  def convert_css_for_tamtam(css)
    css.gsub(/^@import .*/) do |m|
      path = m.gsub(/^@import ['"](.*?)['"];/, '\1')
      dir  = (path =~ /^\/_common\//) ? "#{Rails.root}/public" : Site.public_path
      file = "#{dir}#{path}"
      if FileTest.exist?(file)
        m = ::File.new(file).read.toutf8.gsub(/(\r\n|\n|\r)/, "\n").gsub(/^@import ['"](.*?)['"];/) do |m2|
          p = m2.gsub(/.*?["'](.*?)["'].*/, '\1')
          p = ::File.expand_path(p, ::File.dirname(path)) if p =~ /^\./
          %Q(@import "#{p}";)
        end
      else
        m = ''
      end
      m
    end
  end
end
