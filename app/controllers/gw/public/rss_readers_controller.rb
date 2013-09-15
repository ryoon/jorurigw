class Gw::Public::RssReadersController < ApplicationController
  include System::Controller::Scaffold
  
  def initialize_scaffold
    params[:search] = "検索" if params[:s_keyword]
    return redirect_to(request.env['PATH_INFO']) if params[:reset]
    
    load_params unless params[:search]
    init_params
  end
  
  def index
    return authentication_error(403) unless Gw::RssReader.valid_user?(Site.user.id)
    item = Gw::RssReader.new
    item.search(params)
    item.page(params[:page], params[:limit])
    item.order("sort_no ASC")
    @items = item.find(:all)
    save_params
    _index @items
  end
  
  def show
    return authentication_error(403) unless Gw::RssReader.valid_user?(Site.user.id)
    @item = Gw::RssReader.find(params[:id]) rescue nil
    return http_error(404) if @item.blank? || @item.deleted?
    @item.sort_caches_by_id
    save_params
    _show @item
  end
  
  def new
    return authentication_error(403) unless Gw::RssReader.valid_user?(Site.user.id)
    @item = Gw::RssReader.new
    return http_error(404) if @item.blank? || @item.deleted?
    @item.set_default_value
    save_params
  end
  
  def create
    return authentication_error(403) unless Gw::RssReader.valid_user?(Site.user.id)
    @item = Gw::RssReader.new(params[:item]) rescue nil
    return http_error(404) if @item.blank? || @item.deleted?
    save_params
    _create(@item, :success_redirect_uri => "#{Site.current_node.public_uri}")
    @item.update_caches(Time.now)
  end
  
  def edit
    return authentication_error(403) unless Gw::RssReader.valid_user?(Site.user.id)
    @item = Gw::RssReader.find(params[:id]) rescue nil
    return http_error(404) if @item.blank? || @item.deleted?
    save_params
  end
  
  def update
    return authentication_error(403) unless Gw::RssReader.valid_user?(Site.user.id)
    @item = Gw::RssReader.find(params[:id]) rescue nil
    return http_error(404) if @item.blank? || @item.deleted?
    @item.attributes = params[:item]
    save_params
    _update(@item, :success_redirect_uri => "#{Site.current_node.public_uri}#{@item.id}")
    @item.update_caches(Time.now)
  end
  
  def destroy
    return authentication_error(403) unless Gw::RssReader.valid_user?(Site.user.id)
    @item = Gw::RssReader.find(params[:id]) rescue nil
    return http_error(404) if @item.blank? || @item.deleted?
    @item.set_deleted_value
    save_params
    _update(@item, 
      :success_redirect_uri => Gw.chop_with("#{Site.current_node.public_uri}",'/'),
      :notice => "削除処理が完了しました"
    )
  end
  
  def swap
    return authentication_error(403) unless Gw::RssReader.valid_user?(Site.user.id)
    Gw::RssReader.swap(params[:id], params[:sid])
    save_params
    redirect_to Gw.chop_with("#{Site.current_node.public_uri}",'/')
  end
  
  def edit_props
    @items = Gw::RssReader.find(:all, :conditions => "state = 'enabled'", :order => "sort_no ASC")
    @rssids = Gw::RssReader.read_rssids
    _index @items
  end
  
  def save_props
    rssids = []
    hash_item = params[:item]
    hash_item.each_pair do |rssid, checked|
      if checked.to_i == 1
        rssids << rssid.to_i
      end
    end
    Gw::RssReader.save_rssids(rssids)
    redirect_to '/ind_portal'
  end
  
protected
  
  def init_params
    params[:page] = nz(params[:page], 1)
    params[:limit] = nz(params[:limit], 10)
  end
  
  def load_params
    params[:limit] = flash[:limit] if flash[:limit]
    params[:s_keyword] = flash[:s_keyword] if flash[:s_keyword]
    params[:search] = "検索" if flash[:s_keyword]
  end
  
  def save_params
    flash[:limit] = params[:limit] if params[:limit]
    flash[:s_keyword] = params[:s_keyword] if params[:s_keyword]
  end
end
