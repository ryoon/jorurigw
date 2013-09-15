module Gw::Admin::PortalHelper
  def draw_client(arg)
    case arg.class.to_s
    when 'String'
      return "<table border='0'><tr><td>#{arg}</td></tr></table>"
    when 'Hash'
      table_options = ''
      table_options += " height=\"#{arg['height']}\""
      table_options += " width=\"#{arg['width']}\""
      html = "<table border='1'#{table_options}><tr><td width=\"100%\" height=\"100%\">"
      html += "#{arg}"
      html += "</td></tr></table>"
      return html
    else
      return "<table border='0'><tr><td>Unknown type:#{arg.class}</td></tr></table>"
    end
  end
  def draw_client_main(item, last_width=1000, last_height='x')
    pp last_height
    require 'json_parser'
    options = JsonParser.new.parse(item.options)
    default_size = 300
    core = "#{item.idx.to_s}:#{item.arrange}<br/>"
    core += "#{options['str']}"

    case item.arrange
    when 'top', 'bottom'
      height = (( nz(options['height'], '')=='' ? '' : ' height:'+options['height'].to_s+'px;'))
      last_height = height
      html = '<table style="width:100%;'+height+' border:1px solid;"><tr><td>'+core+'</td></tr></table>'
    when 'left', 'right'
      width = nz(options['width'],default_size)
      if nz(options['height'], '')==''
        height = ''
        last_height = 'x'
      else
        height = ' height:'+options['height'].to_s+'px;'
        last_height = options['height']
      end
      last_width -= width
      html = '<table style="width:'+width.to_s+'px;'+height+' border:1px solid;"><tr><td>'+core+'</td></tr></table>'
    when 'last'
      width = last_width
      if last_height == 'x'
        height = ''
      else
        height = (( nz(options['height'], '')=='' ? '' : ' height:'+options['height'].to_s+'px;'))
      end
      html = '<table style="width:'+width.to_s+'px;'+height+' border:1px solid;"><tr><td>'+core+'</td></tr></table>'
    end
    return [html, last_width, last_height]
  end
  def draw_client_recursive(items, idx=0, last_width=1000, last_height='x')
    html = '<table style="border:none;'
    html += 'width:'+last_width.to_s+'px' if idx==0
    html += '">'
    draw_tmp = draw_client_main(items[idx], last_width, last_height)
    case items[idx].arrange
    when 'top'
      html += '<tr><td>'+draw_tmp[0]+'</td></tr>'
      html += '<tr><td>'+draw_client_recursive(items, idx+1, draw_tmp[1], draw_tmp[2])+'</td></tr>'
    when 'bottom'
      html += '<tr><td>'+draw_client_recursive(items, idx+1, draw_tmp[1], draw_tmp[2])+'</td></tr>'
      html += '<tr><td>'+draw_tmp[0]+'</td></tr>'
    when 'left'
      html += '<tr><td>'+draw_tmp[0]+'</td>'
      html += '<td>'+draw_client_recursive(items, idx+1, draw_tmp[1], draw_tmp[2])+'</td></tr>'
    when 'right'
      html += '<tr><td>'+draw_client_recursive(items, idx+1, draw_tmp[1], draw_tmp[2])+'</td>'
      html += '<td>'+draw_tmp[0]+'</td></tr>'
    when 'last'
      html += '<tr><td>'+draw_tmp[0]+'</td></tr>'
    end
    html += '</table>'
    html
  end
end
