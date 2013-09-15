module System::SubviewsHelper

  def css_view(item)
    css_filename = "public/layout/#{item.name}/style.css"
    begin
      css_file = hbr(open(css_filename).read)
    rescue
      css_file = ''
    end
    ret = <<EOL
<table class="show">
  <tr>
    <th>CSS(ファイル)</th>
    <td>#{css_file}</td>
  </tr>
</table>
EOL
    return ret
  end

  def users_view(items, options = {})
    caption = nz(options[:caption])
    include_table_tag = true if options[:include_table_tag].nil?
    # main
    ret = ''
    ret += '<table class="show">' if include_table_tag
    ret += %Q(<tr><th colspan="2">#{caption}</th></tr>) if caption
    items.each do |x|
      begin
        case x.class_id
        when 0
          th = 'すべて'
          td = ''
        when 1
          th = 'ユーザ'
          td = System::User.find(:first, :conditions => "id=#{x.uid}").display_name
        when 2
          th = 'グループ'
          td = System::Group.find(:first, :conditions => "id=#{x.uid}").name
        end
        ret += "<tr><th>#{th}</th><td>#{td}</td></tr>"
      rescue
      end
    end
    ret += '</table>' if include_table_tag

    ret
  end
end
