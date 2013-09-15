module ApplicationHelper

  def br(str)
    str.to_s.gsub(/\r\n|\r|\n/, '<br />')
  end

  def hbr(str)
    str = html_escape(str.to_s)
    str.gsub(/\r\n|\r|\n/, '<br />')
  end

  def ass(alt = nil, &block)
    begin
      yield
    rescue NoMethodError => e
      here = caller.grep(/gw/).first
        alt
    end
  end

  def convert_for_mobile_body(body,sid=nil)
    ret = Gw::Controller::Mobile.convert_for_mobile_body(body, sid)
    return ret
  end

  def email_to(addr, text = nil)
    text = addr unless text
    addr.gsub!(/@/, '&#64;')
    addr.gsub!(/a/, '&#97;')
    text.gsub!(/@/, '&#64;')
    text.gsub!(/a/, '&#97;')
    mail_to(text, addr)
  end

  def paginate(items, options = {})
    return '' unless items
    default_options = {
      :params     => p,
      :prev_label => '<span class="prev">前のページ</span>',
      :next_label => '<span class="next">次のページ</span>',
      :separator  => '<span class="separator"> | </span' + "\n" + '>',
      :renderer   => Cms::Lib::Pagination
    }
    will_paginate items, default_options.merge!(options)
  end

  def show_notice
    return %Q(<div class="notice">#{flash[:notice]}</div>) if flash[:notice]
  end

  def ruby(str, ruby = nil)
    ruby = Site.ruby unless ruby
    return ruby == true ? Util::Html::Ruby.convert(str) : str
  end

  def ja_name(name, object = nil)
    label = I18n.t name, :scope => [:activerecord, :attributes, object.class.to_s.underscore]
    return label =~ /^translation missing:/ ? name.to_s.humanize : label
  end


  def hbf_struct(prefix, options={})
    header, body, footer = options[:header], options[:body], options[:footer]
    ret = ''
    ret += %Q(<div class="#{prefix}Header">#{header}</div>) if !header.blank?
    ret += %Q(<div class="#{prefix}Header"><h2 class="#{prefix}Title"></h2></div>) if options[:prop_div] == 'prop'
    ret += %Q(<div class="#{prefix}Body">#{body}</div>)
    ret += %Q(<div class="#{prefix}Footer">#{footer}</div>) if !footer.blank?
    return ret
  end

  def hhbff_struct(ident, action, options={})
    body = hbf_struct(:pieceBody, :header=>options[:body][:header], :body=>options[:body][:body], :footer=>options[:body][:footer])
    ret = piece_struct2(ident, action, :header=>options[:header], :body=>body, :footer=>options[:footer], :prop_div=>options[:prop_div])
    return ret
  end

  def piece_struct(ident, action, header = '', body = '', footer = '')
    ret = %Q(<div class="piece #{ident} #{action}">)
    ret += hbf_struct(:piece, :header=>header, :body=>body, :footer=>footer)
    ret += %Q(</div>)
    return ret
  end

  def piece_struct2(ident, action, options={})
    ret = %Q(<div class="piece #{ident} #{action}">)
    ret += hbf_struct(:piece, :header=>options[:header], :body=>options[:body], :footer=>options[:footer], :prop_div=>options[:prop_div])
    ret += %Q(</div>)
    return ret
  end

  def tabbox_struct(tab_captions, selected_tab_idx=nil, options={})
    tab_current_cls_s = ' ' + Gw.trim(nz(options[:tab_current_cls_s], 'current'))
    id_prefix = Gw.trim(nz(options[:id_prefix], nz(options[:name_prefix], '')))
    id_prefix = "[#{id_prefix}]" if !id_prefix.blank?
    tabs = <<-"EOL"
<div class="tabBox">
<table class="tabtable">
<tbody>
<tr>
<td class="spaceLeft"></td>
EOL
    tab_idx = 0
    tab_captions.each_with_index{|x, idx|
      tab_idx += 1
      _name = "tabBox#{id_prefix}[#{tab_idx}]"
      _id = Gw.idize(_name)
      tabs += %Q(<td class="tab#{selected_tab_idx - 1 == idx ? tab_current_cls_s : nil}" id="#{_id}">#{x}</td>) +
        (tab_captions.length - 1 == idx ? '' : '<td class="spaceCenter"></td>')
    }
    tabs += <<-"EOL"
<td class="spaceRight"></td>
</tr>
</tbody>
</table>
</div><!--tabBox-->
EOL
    return tabs
  end
  def search_struct(search_fields, options={})
    submits = <<-EOL
#{submit_tag '検索',     :name => :search}
#{submit_tag 'リセット', :name => :reset}
EOL
    @content_for_form = ''
    content_for :form do
      form_tag '', :method => :get, :class => 'search' do
        if options[:old].blank?
          concat <<-EOL
<div class="indication">
#{ret=''; search_fields.each{|search_field|
  ret += search_field
}; ret}
#{submits}
</div>
EOL
        else
          concat <<-EOL
<table>
<tr>
#{ret=''; search_fields.each{|search_field|
  ret += "<td>#{search_field}</td>"
}; ret}
<td class="submitters">
#{submits}
</td>
</tr>
</table>
EOL
        end
      end
    end
    @content_for_form
  end

  def concept_content_link(item, contents=nil)
    ret = ''
    if !item.nil? && ((item.is_a?(Cms::Content) && item.title == '知事への提言投稿') ||
        (item.is_a?(Cms::Concept) && item.name == '知事への提言') ||
        (item.is_a?(Cms::Concept) && item.name == 'ようこそ知事室へ'))
      ret += link_to('知事への提言', governor_opinion_posts_path)
      ret += '<br />'
    else
      if contents.nil?
        ret += concept_content_link_core(item)
      else
        contents.each do |c|
          ret += concept_content_link_core(c)
          ret += '<br />'
        end
      end
    end
    return ret
  end

  def concept_content_link_core(c)
    begin
      link_to(h(c.title), eval(c.admin_path_name))
    rescue
      h(c.title)
    end
  end

  def required_head
    Gw.required_head
  end

  def required(str='※')
    Gw.required(str)
  end

  def nobr(str)
    Gw.nobr(str)
  end

  def div_notice(str=nil)
    str = nz(str, flash[:notice])
    Gw.div_notice(str)
  end

  def set_focus_to_id(id)
    javascript_tag("$('#{id}').focus()");
  end

end
