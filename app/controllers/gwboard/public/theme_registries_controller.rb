class Gwboard::Public::ThemeRegistriesController < ApplicationController
  include Gwboard::Controller::Scaffold
  include Gwboard::Controller::Authorize
  include Gwboard::Controller::Common

  def initialize_scaffold
    @title = nil
    @title = Gwboard::Theme.find_by_id(params[:id]) unless params[:id].blank?

    css_path = ''
    css_path = "/_attaches/css/#{@title.system_name}/#{@title.id}.css" unless @title.blank?
    if css_path.blank?
       @css = ["/_common/themes/gw/css/gwbbs_standard.css", "/_common/themes/gw/css/doc_2column.css"]
    else
      f_path = "#{RAILS_ROOT}/public/#{css_path}"
      if FileTest.exist?(f_path)
        @css = [css_path, "/_common/themes/gw/css/gwbbs_standard.css", "/_common/themes/gw/css/doc_2column.css"]
      else
        @css = ["/_common/themes/gw/css/gwbbs_standard.css", "/_common/themes/gw/css/doc_2column.css"]
      end
    end
  end

  def index
    item = Gwboard::Theme.new
    item.and :content_id, '>=' , 3
    item.page params[:page], params[:limit]
    @items = item.find(:all)
  end

  def new
    set_select_data
    @item = Gwboard::Theme.new({
      :if_bg_setup => '0',
      :if_css => '#FFFCF0' ,
      :if_font_color => '#000000'
    })
  end

  def create
    @item = Gwboard::Theme.new(params[:item])
    if @item.state == 'prev'
      @item.content_id = 1
      @item.save
      location = "#{Site.current_node.public_uri}#{@item.id}/edit"
      redirect_to location
    else
      @item.content_id = 7
      location = Gw.chop_with("#{Site.current_node.public_uri}",'/')
      _create(@item,:success_redirect_uri=>location)
    end
  end

  def show
    @item = Gwboard::Theme.find_by_id(params[:id])
    @item.params_check_and_reset if @item.content_id == 3

    @icon_item = Gwboard::Image.find_by_id(@item.icon_id)
    @wallpaper_item = Gwboard::Image.find_by_id(@item.wallpaper_id)

  end

  def edit
    set_select_data
    @item = Gwboard::Theme.find_by_id(params[:id])
  end

  def update
    set_select_data
    @item = Gwboard::Theme.new.find(params[:id])
    @item.attributes = params[:item]
    @item.content_id = 3  if @item.state == 'prev'
    unless @item.state == 'public'
      @item.save
      location = "#{Site.current_node.public_uri}#{@item.id}/edit"
      redirect_to location
    else
      @item.content_id = 7
      _update @item
    end
  end

  def destroy

  end

  def set_select_data
    @icons = get_icons
    @wallpapers = get_wallpapers
    @bg_colors = Gwboard::Bgcolor.find(:all,:conditions=>'content_id=0',:order=>'id')
    @font_colors = Gwboard::Bgcolor.find(:all,:conditions=>'content_id=1',:order=>'id')
  end

  def get_wallpapers
    sql = Condition.new
    sql.or {|d|
      d.and :share , 0
      d.and :range_of_use , 0
      d.and :section_code , Site.user_group.code
    }
    sql.or {|d|
      d.and :share , 0
      d.and :range_of_use , 10
      d.and :section_code , Site.user_group.code
    }
    sql.or {|d|
      d.and :share , 2
      d.and :range_of_use , 0
    }
    sql.or {|d|
      d.and :share , 2
      d.and :range_of_use , 10
    }
    item = Gwboard::Image.new
    return item.find(:all, :conditions => sql.where, :order=>'share, id')
  end

  def get_icons
    sql = Condition.new
    sql.or {|d|
      d.and :share , 1
      d.and :range_of_use , 0
      d.and :section_code , Site.user_group.code
    }
    sql.or {|d|
      d.and :share , 1
      d.and :range_of_use , 10
      d.and :section_code , Site.user_group.code
    }
    sql.or {|d|
      d.and :share , 3
      d.and :range_of_use , 0
    }
    sql.or {|d|
      d.and :share , 3
      d.and :range_of_use , 10
    }
    item = Gwboard::Image.new
    return item.find(:all, :conditions => sql.where, :order=>'share, id')
  end

end
