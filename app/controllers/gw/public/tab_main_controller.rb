class Gw::Public::TabMainController < ApplicationController

  def initialize_scaffold
    return redirect_to(request.env['PATH_INFO']) if params[:reset]
  end

  def init_params
    @css = %w(/_common/themes/gw/css/portal_common.css)
    item    = Gw::AdminMessage.new
    cond    = 'state = 1'
    order   = 'state ASC , sort_no ASC , updated_at DESC'
    @items  = item.find(:all,:conditions=>cond,:order=>order)
    @is_gw_admin = Gw.is_admin_admin?
  end

  def show
    init_params

    cond  = " level_no=2 and published='opened' "
    order = " sort_no "
    tab_names = Gw::EditTab.find(:all,:conditions=>cond,:order=>order)
    return http_error(404) if tab_names.blank?

    tabs = []
    tab_names.each do |tab|
      tabs << [tab.tab_keys , tab.other_controller_url ,tab.name ]
    end

    @piece_param = params[:id]
    cond  = " level_no=2 and published='opened' and tab_keys=#{params[:id].to_i}"
    order = " sort_no "
    tab_main = Gw::EditTab.find(:first,:conditions=>cond,:order=>order)
    return http_error(404) if tab_main.blank?

    cur = nz(@piece_param, "1")
    tabs.each_with_index do |tab, idx|
      Page.title = 'JoruriGw '+tab[2] if tab[0].to_s == cur
    end

    @content = make_views(tab_main, @is_gw_admin)
    @content = <<EOL
<div id="basic" class="piece">
<div class="pieceContainer">
<div class="pieceBody">
#{@content}
</div>
</div>
</div>
EOL
  end

  def make_views(tab_main, is_gw_admin = Gw.is_admin_admin?)
    cond  = " level_no=3 and published='opened' and state!='deleted' and parent_id=#{tab_main.id}"
    order = " sort_no "
    tab_main_blocks = Gw::EditTab.find(:all,:conditions=>cond,:order=>order)
    return content = nil if tab_main_blocks.blank?

    content = <<EOL
    <div id="pref">
EOL

    i = 0
    tab_main_blocks.each_with_index do |blk,idx|
      if is_gw_admin || blk.is_public?
        if i.to_i%2==0
          content << %Q(<div class="clearfix"></div>)
        end
        content << %Q(<div class="box">)
        content << %Q( <h3>#{blk.name}</h3> )
        content << %Q( <div class="menu"> )
        content << %Q( <ul> )

        child_opt = {:published=>'opened'}
        links = blk.get_child(child_opt)
        links.each do |lnk|
          if is_gw_admin || lnk.is_public?
            if blk.state=='disabled'
              lnk_str = set_lnk_str(lnk,3)
            else
              if lnk.state=='disabled'
                lnk_str = set_lnk_str(lnk,3)
              else
                lnk_str = set_lnk_str(lnk,lnk.class_external)
              end
            end
            content << lnk_str
          end
        end
        content << %Q(</ul>)
        content << %Q(</div>)
        content << %Q(</div>)
        i += 1
      end
    end
    content << <<EOL
    </div>
EOL
    return content
  end

  def set_lnk_str(lnk,param)
    link_str = ""
    case param
    when 3

      if lnk.class_external==1

        link_str += %Q(<li class="grayout">)
        link_str += %Q(<a )
        link_str += %Q( href="##{lnk.link_url}"> )
        link_str += %Q(#{lnk.name})
        link_str += %Q(</a>)
        link_str += %Q(</li>)
      else
        if lnk.class_external==2

          if lnk.class_sso == 1

            link_str += %Q(<li class="grayout">)
            link_str += %Q(<a )
            link_str += %Q( href="##{lnk.link_url}" class="ext" target="_blank" >)
            link_str += %Q(#{lnk.name})
            link_str += %Q(</a>)
            link_str += %Q(</li>)
          else
            if lnk.class_sso == 2

            else

              link_str += %Q(<li class="grayout">)
              link_str += %Q(#{lnk.name})
              link_str += %Q(</li>)
            end
          end
        else

          link_str += %Q(<li class="grayout">)
          link_str += %Q(#{lnk.name})
          link_str += %Q(</li>)
        end
      end
    when 1

      if lnk.icon_path.blank?

        link_str += %Q(<li>)
        link_str += %Q(<a href="#{lnk.link_url}">)
        link_str += %Q(#{lnk.name})
        link_str += %Q(</a>)
        link_str += %Q(</li>)
      else

        link_str += %Q(<li>)
        link_str += %Q(<a href="#{lnk.link_url}">)
        link_str += %Q(<img src="#{lnk.icon_path}" />)
        link_str += %Q(</a>)
        link_str += %Q(#{lnk.name})
        link_str += %Q(</li>)
      end
    when 2

      if lnk.class_sso == 1

        link_str += %Q(<li>)
        link_str += %Q(<a href="#{lnk.link_url}" class="ext" target="_blank" >)
        link_str += %Q(#{lnk.name}</a>)
        link_str += %Q(</a>)
        link_str += %Q(</li>)
      else
        if lnk.class_sso == 2
        else

          link_str += %Q(<li>)
          link_str += %Q(#{lnk.name})
          link_str += %Q(</li>)
        end
      end
    else

      link_str += %Q(<li>)
      link_str += %Q(#{lnk.name})
      link_str += %Q(</li>)
    end
    return link_str
  end
end
