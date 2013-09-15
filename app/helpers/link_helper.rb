module LinkHelper

  def link_external?(uri)
    require 'uri'
    return false if uri.index('://').nil?
    parsed = URI.parse(uri)
    case parsed.class.to_s
    when 'URI::Generic'
      return false
    when 'URI::HTTP'
      rails_env = ENV['RAILS_ENV']
      rails_env = 'development' if rails_env == 'test'
      trans_hash_raw = YAML.load_file('config/site.yml')
      return ( parsed.host != trans_hash_raw[rails_env]['domain'] ) rescue raise 'site.yml の設定を見直してください。'
    else
      return true
    end
  end

  def link_internal?(uri)
    return !link_external?(uri)
  end

  def link_to_internal(caption, uri, options={})
    return link_to(caption, uri, options)
  end

  def link_to_external(caption, uri, options={})
    options_wrk = options.dup
    options_wrk['class'] = 'ext'
    return link_to(caption, uri, options_wrk)
  end

  def link_to_with_external_check(caption, uri, options={})
    options_wrk = options.dup
    options_wrk['class'] = 'ext' if link_external?(uri)
    return link_to(caption, uri, options_wrk)
  end

  alias link_to_wec link_to_with_external_check

  def link_to_extention_piece(piece)
    mod  = (piece.content ? piece.content.module : 'cms').camelize
    ctr  = piece.controller.camelize
    path = nil
    begin
      helper = eval("#{mod}::Piece::#{ctr}Helper")
      path = extention_piece_path(piece)
    rescue
      return ''
    end
    link_to '拡張設定', path
  end

  def link_to_list(item, caption = '展開', options={})
    case Site.mode
    when 'admin'
      link_to_with_external_check caption, url_for(:action => :index, :parent => item)
    when 'public'
      return nil if options[:vri].nil?
    end
  end

  alias :link_to_explore :link_to_list

  def link_to_show(item, caption = '詳細', options={})
    caption = nz(caption, '詳細')
    case Site.mode
    when 'admin'
      uri = url_for(:action => :show, :id => item)
    when 'public'
      uri = url_for("#{Site.current_node.public_uri}#{item}")
    end
    link_to_with_external_check caption, uri, options
  end

  def link_to_edit(item, caption = '編集', options={})
    caption = nz(caption, '編集')
    case Site.mode
    when 'admin'
      uri = url_for(:action => :edit, :id => item)
    when 'public'
      uri = url_for("#{Site.current_node.public_uri}#{item}/edit")
    end
    opt = options.dup
    uri = "#{uri}?#{opt[:qs]}" if !opt[:qs].blank?
    opt.delete :qs
    link_to_with_external_check caption, uri, opt
  end

  def link_to_destroy(item, caption = '削除', options={})
    caption = nz(caption, '削除')
    opt = HashWithIndifferentAccess.new(options)
    opt[:confirm] = nz(options[:confirm], '削除してよろしいですか？')
    opt[:method] = :delete
    case Site.mode
    when 'admin'
      uri = url_for(:action => :destroy, :id => item)
    when 'public'
      uri = url_for("#{Site.current_node.public_uri}#{item}")
    end
    uri = "#{uri}?#{opt[:qs]}" if !opt[:qs].blank?
    opt.delete :qs
    link_to_with_external_check caption, uri, opt
  end

  def link_to_preview(item)
    link_to_with_external_check '表示', item.preview_uri, :target => '_blank'
  end

  def link_to_recognize(item)
    link_to_with_external_check '承認', url_for(:action => :show, :id => item, :do => :recognize), :confirm => '承認してよろしいですか？'
  end

  def link_to_publish(item)
    link_to_with_external_check '公開', url_for(:action => :show, :id => item, :do => :publish), :confirm => '公開してよろしいですか？'
  end

  def link_to_rebuild(item)
    link_to_with_external_check '再構築', url_for(:action => :show, :id => item, :do => :rebuild), :confirm => '再構築してよろしいですか？'
  end

  def link_to_close(item)
    link_to_with_external_check '非公開', url_for(:action => :show, :id => item, :do => :close), :confirm => '公開を終了してよろしいですか？'
  end

  def link_to_status(item)
    link_to_with_external_check item.status.name, url_for(:action => :show, :id => item)
  end

  def link_to_index(caption = nil, url = nil, options={})
    opt = options.dup
    caption = nz(caption, '一覧へ戻る')
    url = url_for(url.nil? ? chop_with(Site.current_node.public_uri, '/') : url)
    url = "#{url}?#{opt[:qs]}" if !opt[:qs].blank?
    opt.delete :qs
    case Site.mode
    when 'admin'
      raise 'link_to_index not supposed on admin mode.'
    when 'public'
      link_to_with_external_check caption, url, opt
    end
  end

  def link_to_new(caption = '新規作成')
    case Site.mode
    when 'admin'
      raise 'link_to_new not supposed on admin mode.'
    when 'public'
      link_to_with_external_check caption, url_for("#{Site.current_node.public_uri}new")
    end
  end

  def chop_with(str, suffix)
    return Gw.chop_with(str, suffix)
  end

  def link_to_content(content_name, link_function_name, caption = '一覧', accesskey = nil)
    rec = Cms::Content.find(:first, :select => 'id', :conditions => ["name = ?", content_name])
    ret = link_to_with_external_check caption, eval(link_function_name + '(rec ? rec[:id] : nil)'), :accesskey=>accesskey
    ret = "<div class='notice'>contents #{content_name} not found.</div>" if rec.nil?
    return ret
  end

  def sort_link(title, sort_keys, path_index, field_name, other_query_string='')
    other_query_string = nz(other_query_string, '')
    ret = sort_keys == "#{field_name}%20asc" ? '▲' : link_to_with_external_check('▲', path_index + "?sort_keys=" + "#{field_name}%20asc" + (other_query_string=='' ? '' : '&amp;' + other_query_string ))
    ret += ' '
    ret += sort_keys == "#{field_name}%20desc" ? '▼' : link_to_with_external_check('▼', path_index + "?sort_keys=" + "#{field_name}%20desc" + (other_query_string=='' ? '' : '&amp;' + other_query_string ))
    ret += "<br />"
    ret += title
    return ret
  end

  def link_to_do(action, caption)
    case Site.mode
    when 'admin'
      raise 'link_to_do not supposed on admin mode.'
    when 'public'
      link_to_with_external_check caption, url_for("#{Site.current_node.public_uri}#{action}")
    end
  end

  def link_to_id(action, id, caption, base_uri=nil)
    case Site.mode
    when 'admin'
      raise 'link_to_id not supposed on admin mode.'
    when 'public'
      link_to_with_external_check caption, url_for("#{base_uri.nil? ? Site.current_node.public_uri : base_uri}#{id}/#{action}")
    end
  end

  def link_to_uc(caption, uri=nil, options={})
    options_wrk = options.dup
    options_wrk[:class] = Gw.join([options_wrk[:class], :mock], ' ')
    alt_uri = Gw.alternate_uri(uri, options)
    link_to caption, alt_uri, options_wrk
  end
end