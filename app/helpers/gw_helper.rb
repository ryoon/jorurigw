module GwHelper

  def grouplist4(fyear_id=nil, all = nil, role = true ,top = nil ,parent_id=nil, options={})
    # fyear_id 対象年度id
    # all   選択リストに'すべて'を含む指定   'all':含む
    # role : 権限
    # top : true の時は、level_no =1 から表示
    # parent_id : 指定があれば、上位部署で絞る
    # 年度指定が無ければ、今日を含む年度
    if fyear_id.to_i==0
      fyear_target_id = Gw::YearFiscalJp.get_record(Time.now).id
    else
      fyear_target_id = fyear_id
    end

    start_at_fyear  = Gw::YearFiscalJp.find(fyear_target_id).start_at

    if role != true
      grp = Site.user_group
      group_select = []
      if options.has_key?(:code) and options[:code] == 'none'
        group_select << [grp.name,grp.id]
      else
        group_select << ['('+grp.code+')'+grp.name,grp.id]
      end
      return group_select
    end

    current_time = Time.now
    group_cond    = "state='enabled' and level_no=2 "

    group_cond    << " and id=#{parent_id}"  unless parent_id.to_i==0
    group_cond    << " and start_at <= '#{current_time.strftime("%Y-%m-%d 00:00:00")}'"

    group_cond    << " and (end_at IS Null or end_at = '0000-00-00 00:00:00' or end_at > '#{current_time.strftime("%Y-%m-%d 23:59:59")}' ) "
    group_order   = "code , sort_no , start_at DESC, end_at IS Null ,end_at DESC"
    group_parents = System::GroupHistory.find(:all,:conditions=>group_cond,:order=>group_order)

    group_select = []
    if group_parents.blank?
      group_select << ["所属未設定",0]
      return group_select
    end

    group_select << ["すべて",0]  if all == 'all'

    if top == true
      top_g  = System::GroupHistory.find(1)
      if options.has_key?(:code) and options[:code] == 'none'
        group_select << [top_g.name,top_g.id]
      else
        group_select << ['('+top_g.code+')'+top_g.name,top_g.id]
      end
    end

    l3_code_len = Site.code_length(3)
    for group in group_parents
      child_cond    = "state='enabled' and level_no=3 and parent_id=#{group.id}"
      child_cond    << " and start_at <= '#{current_time.strftime("%Y-%m-%d 00:00:00")}'"

      child_cond    << " and (end_at IS Null or end_at = '0000-00-00 00:00:00' or end_at > '#{current_time.strftime("%Y-%m-%d 23:59:59")}' ) "
      child_order   = "code , sort_no , start_at DESC, end_at IS Null ,end_at DESC"
      children = System::GroupHistory.find(:all,:conditions=>child_cond,:order=>child_order)

      unless children.blank?
        children.each_with_index do |child , i|
          # level_no = 2
          if i == 0 and options.has_key?(:code) and options[:code] == 'none'
            group_select  << ["#{group.name}", group.id]
          else
            group_select << ["(#{group.code})#{group.name}" , child.id] if i == 0 && (options[:return_pattern].blank? || options[:return_pattern] == 0)
            group_select << ["(#{group.code})#{group.name}", child.id, group ] if i == 0 && options[:return_pattern] == 1
            group_select  << ["(#{group.code})#{group.name}", group.id] if i == 0 && options[:return_pattern] == 2
          end
          # level_no = 3
          if options.has_key?(:code) and options[:code] == 'none'
            group_select << ["　　 - #{child.name}" , child.id]
          else
            group_select << ["　　 - (#{child.code.to_s.rjust(l3_code_len.to_i,'0')})#{child.name}", child.id] if options[:return_pattern].blank? || options[:return_pattern] == 0
            group_select << ["　　 - (#{child.code.to_s.rjust(l3_code_len.to_i,'0')})#{child.name}", child.id, child] if options[:return_pattern] == 1
            group_select << ["　　 - (#{child.code.to_s.rjust(l3_code_len.to_i,'0')})#{child.name}", child.id] if options[:return_pattern] == 2
            group_select << [child.name, "child_group_#{child.id}"] if options[:return_pattern] == 3 # スケジューラー登録画面での所属検索用
            group_select << [child.name, "#{child.id}"] if options[:return_pattern] == 4 # スケジューラー登録画面での所属検索用
          end
#          if options[:value_str].blank?
#            group_select << ["#{child.name}", "group_#{child.id}"]
#          else
#            group_select << ["#{child.name}", "#{options[:value_str]}_#{child.id}"]
#          end
        end
      end
    end
    return group_select
  end

  def newline_to_br(text)
    text.to_s.gsub(/\r\n|\r|\n/, "<br />")
  end
  def date_format(format, d)
    Gw.date_format(format, d)
  end

  def mock_for_select(str, _options={})
    options = HashWithIndifferentAccess.new(_options)
    idx = 0
    delim = nz(options[:delim], ':')
    in_a = str.is_a?(Array) ? str : str.split(delim)
    ret = in_a.collect{|x|
      idx+=1
      if !options[:value_as_label].blank?
        [x,x]
      elsif !options[:with_idx].blank?
        [idx,x]
      elsif options[:for_radio].nil?
        ['',x]
      else
        [x, idx]
      end
    }
    return options[:to_s].blank? ? ret : Gw.options_for_select(ret, options[:selected])
  end

  def opt_schedule_week_1st
    mock_for_select '日曜:月曜', :for_radio=>1
  end

  def show_group_link(id, options={})
    opt_user_types = Gw.yaml_to_array_for_select('gw_users_class_types')

    if options[:priv] == :edit
      opt_user_types += [ ["職員選択（他所属）" , "all_group" ] ]
    else
      opt_user_types += [ ["所属検索" , "all_group" ] ]
    end

    g = Site.user.groups
    rep = opt_user_types.rassoc '_belong'
    rep[0] = g[0].name if !rep.blank?

    opt_user_types += [ ["-----------------" , "-" ] ]
    tmp_prefix = ''
    glist = System::CustomGroup.get_my_view( { :priv => options[:priv] } )
    glist.each {|x|
      if options[:mode] == :form_schedule
       if x.is_default == 1 && rep[0] == x.name
         opt_user_types.delete_at(opt_user_types.index(rep)) if !opt_user_types.index(rep).blank?
         options[:selected] = "custom_group_#{x.id}"
       end
      end
      if tmp_prefix == '' && x.sort_prefix != ''
#        opt_user_types += [ ["-----------------" , "-" ] ]
      end
      prefix = (x.sort_prefix == '' ? '' : '個）')
      opt_user_types += [ [ prefix + x.name , 'custom_group_'+x.id.to_s ] ]
      tmp_prefix = x.sort_prefix
    }

    rep = opt_user_types.rassoc '_prop_genre_extras'
    if !rep.blank?
      prop_genre_extras = Gw::ScheduleProp.get_genre_select :key_prefix => 'prop_'
      opt_user_types[opt_user_types.index(rep),1] = prop_genre_extras
    end

    mode = options[:mode]
    options.delete :mode
    case mode
    when :form_memo
      enabled_group = System::Group.find(:all,
        :conditions=>"state='enabled' ",
        :order=>'sort_no, code, name').collect{|x| [x.name, "memo_group_#{x.id.to_s}"]}
      opt_user_types = enabled_group
      options[:selected]="memo_group_#{Site.user_group.id.to_s}"
      include_blank=nil
    when :form_schedule
      %w(prop leader).each do |y|
        opt_user_types = opt_user_types.select{|x| %r(#{y}) !~ x[1]}
      end
      include_blank=nil
    when :form_schedule_child
      opt_user_types = grouplist4(nil, nil , true , nil, nil, {:return_pattern => 3})
      options[:selected]="child_group_#{Site.user_group.id.to_s}"
      include_blank=nil
    else
      %w(_belong).each do |y|
        opt_user_types = opt_user_types.select{|x| %r(#{y}) !~ x[1]}
      end
      include_blank=1
    end

    opt_user_types = Gw.options_for_select(opt_user_types, options[:selected], :include_blank=>include_blank, :to_s=>1, :title=>:n1)
    opt = options.dup
    opt.delete :select
    ret = select_tag(id, opt_user_types, opt)
    return ret
  end

  def show_all_groups_hidden_popups(d, options={})
    opt_user_types = Gw.yaml_to_array_for_select('gw_users_class_types')
    return '' if opt_user_types.rassoc('all_group').nil?
    ret = '<div id="popup_select_group_2" class="yuimenu"><div class="bd"><ul class="first-of-type">'
    System::Group.find(:all, :conditions=>'level_no=2').each do |x|
      ret += %Q(\n<li class="yuimenuitem"><a class="yuimenuitemlabel" href="\#x#{x.id}">#{x.name}</a>)
      ret += %Q(<div id="x#{x.id}" class="yuimenu"><div class="bd"><ul>)
      System::Group.find(:all, :conditions=>"parent_id=#{x.id}").each do |y|
        ret += %Q(\n<li class="yuimenuitem"><a class="yuimenuitemlabel" href="/gw/schedules?gid=#{y.id}&amp;s_date=#{Gw.date8_str(d)}">#{y.name}</a></li>)
      end
      ret += %Q(</ul></div></div></li>)
    end
    ret += '</ul></div></div>'
    ret += <<-EOL
<script type="text/javascript">
//<![CDATA[
  //var myMenu = new YAHOO.widget.Menu('popup_select_group');
  var oMenu = new YAHOO.widget.Menu("popup_select_group_2");
  /*
  YAHOO.util.Event.onContentReady("productsandservices", function () {
    var oMenu = new YAHOO.widget.Menu("productsandservices", { fixedcenter: true });
    oMenu.render();
  YAHOO.util.Event.addListener("menutoggle", "click", oMenu.show, null, oMenu); */
//]]>
</script>
    EOL
    ret
  end

  def date_time_field(f, field_name)
    return %Q[#{f.text_field field_name, :style => 'width:10em;'}] +
      %Q[<button type="button" id="#{field_name}_bt" onclick="showCalendar('#{field_name}_bt','#{f.object_name}_#{field_name}')" class="show_cal_bt"></button>]
  end

  def get_form_title_div(_params)
    class_a  = %w(formTitle)
    class_a.push case _params[:action]
    when 'new', 'create'
      'new'
    when 'quote'
      'quote'
    when 'edit', 'editlending', 'update', 'edit_1', 'edit_2'
      get_repeat_mode(_params) == 1 ? 'edit' : 'editRepeat'
    else
    end
    %Q(<div class="#{Gw.join(class_a, ' ')}">#{get_form_title _params}</div>)
  end

  def get_form_title(_params)
    case _params[:action]
    when 'new', 'create'
      '新規作成'
    when 'quote'
      '引用作成'
    when 'edit', 'editlending', 'update', 'edit_1', 'edit_2'
      get_repeat_mode(_params) == 1 ? '編集' : '繰り返し編集'
    else
    end
  end

  def get_repeat_mode(_params)
    (!_params[:repeat].nil? ? 2 : _params[:init].nil? ? 1 : nz(_params[:init][:repeat_mode], 1)).to_i
  end

  def gw_js_include_full
    return gw_js_include_yui + gw_js_include_popup_calendar
  end

  def gw_js_include_yui
    return <<EOL
<script type="text/javascript" src="/_common/js/yui/build/yahoo-dom-event/yahoo-dom-event.js"></script>
<script type="text/javascript" src="/_common/js/yui/build/element/element-min.js"></script>
<script type="text/javascript" src="/_common/js/yui/build/button/button-min.js"></script>
<script type="text/javascript" src="/_common/js/yui/build/container/container-min.js"></script>
<script type="text/javascript" src="/_common/js/yui/build/calendar/calendar-min.js"></script>
EOL
  end

  def gw_js_include_popup_calendar
    return <<EOL
<script type="text/javascript" src="/_common/js/popup_calendar/popup_calendar.js"></script>
EOL
  end

  def gw_js_ind_popup
    return <<EOL
<script type="text/javascript">
//<![CDATA[
  var gw_js_ind_popup = function() {
    YAHOO.namespace("example.container");
    if (!is_ie()) {
      document.body.addClassName('yui-skin-sam');
      tooltips = document.getElementsByClassName('ind');
      for (var i = 0; i < tooltips.length; i++) {
        YAHOO.example.container.tt1 = new YAHOO.widget.Tooltip("tooltip", { context:tooltips[i]['id'] });
      }
    }
  }
  // window.onload = my_load;
//]]>
</script>
EOL
  end

  def memos_tabbox_struct(send_cls, _qsa)
    qsa = _qsa.nil? ? [] : _qsa
    qs_without_send_cls = Gw.qsa_to_qs(qsa.select{|x| x[0] != 's_send_cls'})
    qs_without_send_cls = qs_without_send_cls.blank? ? '' : "&amp;#{qs_without_send_cls}"
    idx = 0
    tab_captions = %w(受信 送信 ).collect{|x| idx+=1; %Q(<a href="/gw/memos?s_send_cls=#{idx}#{qs_without_send_cls}">#{x}</a>)}
    tabbox_struct tab_captions, send_cls.to_i
  end

  def schedule_settings
    get_settings 'schedules'
  end

  def schedule_prop_settings
    get_settings 'schedule_props'
  end

  def get_settings(key, options={})
    Gw::Model::Schedule.get_settings key, options
  end

  def out_form_ind(key, options={})
    item = @item
    if key == 'ssos'
      item = item['pref_soumu']
      item = {} if item.blank?
    end
    styles = nz(options[:styles], {})
    trans_a = Gw.yaml_to_array_for_select("gw_#{key}_settings_ind")
    trans_hash = Gw::NameValue.get('yaml', nil, "gw_#{key}_settings_ind")
    errors = nz(item['errors'], [])
    textarea_fields = nz(trans_hash['_textarea_fields'], [])
    textarea_fields = textarea_fields.split(':') if !textarea_fields.is_a?(Array)
    password_fields = nz(trans_hash['_password_fields'], [])
    password_fields = password_fields.split(':') if !password_fields.is_a?(Array)
    object_name = :item
    content_for :form do
      form_for :item, :url => "/gw/schedules/edit_ind_#{key}", :html => {:method=>:put, :multipart => true} do |f|
        concat nz(Gw.error_div(item['errors']))
        concat hidden_field_tag('key', key)
        concat '<table class="show">'
        trans_a.each do |_trans|
          col = _trans[1]
          split_trans = _trans[0].split(':')
          trans = _trans[0]
          tag_name = "#{object_name}[#{col}]" rescue col
          tag_id = Gw.idize(tag_name)
          field_str, value_str = if textarea_fields.index(col).nil?
            case split_trans[0]
            when 'r'
              [split_trans[1], select_tag(tag_name, Gw.yaml_to_array_for_select(split_trans[2], :to_s=>1, :selected=>item[col]))]
            else
              style = nz(styles[col], 'width:30em;')
                if password_fields.index(col).nil?
                  val = text_field_tag(tag_name, item[col], :style => style)
                else
                  val = item[col]
                  val = val.decrypt if !val.blank?
                  val = password_field_tag(tag_name, val, :style => style)
                end
                trans = col.humanize if trans == ''
                [h(trans), val]
            end
          else
            [h(trans), form_text_area(f, col)]
          end
          value_str = %Q(<div class="fieldWithErrors">#{value_str}</div>) if !errors.assoc(col).nil?
          concat "<tr><th>#{field_str}</th><td>#{value_str}</td></tr>"
        end
        concat '</table>'
        submit_options={}
        submit_options[:id]="item_submit_#{key}"
        case @key
        when 'mobiles'
          submit_options[:caption] = '保存'
        when 'ssos'
          submit_options[:caption] = '保存する'
        else
          if options[:caption].nil?
            submit_options[:caption] = '編集する'
          else
            submit_options[:caption] = options[:caption]
          end
        end
        concat submit_for_update(f, submit_options)
      end
    end
    return @content_for_form
  end
end
