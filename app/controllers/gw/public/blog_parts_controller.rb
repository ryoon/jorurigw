class Gw::Public::BlogPartsController < ApplicationController
  include System::Controller::Scaffold
  
  def initialize_scaffold
    return redirect_to(request.env['PATH_INFO']) if params[:reset]
  end
  
  def index
    return authentication_error(403) unless Gw::BlogPart.valid_user?(Site.user.id)
    item = Gw::BlogPart.new
    item.search(params)
    item.page(params[:page], params[:limit])
    item.order("sort_no ASC")
    @items = item.find(:all)
    _index @items
  end
  
  def show
    return authentication_error(403) unless Gw::BlogPart.valid_user?(Site.user.id)
    @item = Gw::BlogPart.find(params[:id]) rescue nil
    return http_error(404) if @item.blank? || @item.deleted?
    _show @item
  end
  
  def new
    return authentication_error(403) unless Gw::BlogPart.valid_user?(Site.user.id)
    @item = Gw::BlogPart.new
    return http_error(404) if @item.blank? || @item.deleted?
    @item.set_default
  end
  
  def create
    return authentication_error(403) unless Gw::BlogPart.valid_user?(Site.user.id)
    @item = Gw::BlogPart.new(params[:item]) rescue nil
    return http_error(404) if @item.blank? || @item.deleted?
    _create(@item, :success_redirect_uri => "#{Site.current_node.public_uri}")
  end
  
  def edit
    return authentication_error(403) unless Gw::BlogPart.valid_user?(Site.user.id)
    @item = Gw::BlogPart.find(params[:id]) rescue nil
    return http_error(404) if @item.blank? || @item.deleted?
  end
  
  def update
    return authentication_error(403) unless Gw::BlogPart.valid_user?(Site.user.id)
    @item = Gw::BlogPart.find(params[:id]) rescue nil
    return http_error(404) if @item.blank? || @item.deleted?
    @item.attributes = params[:item]
    _update(@item, :success_redirect_uri => "#{Site.current_node.public_uri}#{@item.id}")
  end
  
  def destroy
    return authentication_error(403) unless Gw::BlogPart.valid_user?(Site.user.id)
    @item = Gw::BlogPart.find(params[:id]) rescue nil
    return http_error(404) if @item.blank? || @item.deleted?
    @item.set_deleted
    _update(@item, 
      :success_redirect_uri => Gw.chop_with("#{Site.current_node.public_uri}",'/'),
      :notice => "削除処理が完了しました"
    )
  end
  
  def swap
    return authentication_error(403) unless Gw::BlogPart.valid_user?(Site.user.id)
    item1 = Gw::BlogPart.find(params[:id]) rescue nil
    item2 = Gw::BlogPart.find(params[:sid]) rescue nil
    return http_error(404) if item1.blank? || item1.deleted?
    return http_error(404) if item2.blank? || item2.deleted?
    Gw::BlogPart.swap(item1, item2)
    redirect_to Gw.chop_with("#{Site.current_node.public_uri}",'/')
  end
  
  def edit_props
    @items = Gw::BlogPart.find(:all, :conditions => "state = 'enabled'", :order => "sort_no ASC")
    uitems = Gw::BlogPart.read_user_props
    @ids = []
    uitems.each do |uitem|
      @ids << uitem['id']
    end
    _index @items
  end
  
  def save_props
    if !params[:mode].blank? && !params[:id].blank?
      id = params[:id].to_i
      case params[:mode]
        when 'add'
          uitems = Gw::BlogPart.read_user_props
          uitems << {'id' => id} if uitems.select{|x|x['id']==id}.length == 0
          uitems.sort! {|a,b| a['id'] <=> b['id']}
          Gw::BlogPart.save_user_props(uitems)
        when 'delete'
          uitems = Gw::BlogPart.read_user_props
          uitems.reject! {|x| x['id'] == id}
          Gw::BlogPart.save_user_props(uitems)
      end
    end
    redirect_to "#{Site.current_node.public_uri}edit_props"
  end
  
protected
  
  before_filter :load_params
  after_filter :save_params
  
  def load_params
    params[:search] = "検索" if params[:s_keyword]
    unless params[:search]
      params[:limit] = flash[:limit] if flash[:limit]
      params[:s_keyword] = flash[:s_keyword] if flash[:s_keyword]
      params[:search] = "検索" if flash[:s_keyword]
    end
    params[:page] ||= 1
    params[:limit] ||= 10
  end
  
  def save_params
    flash[:limit] = params[:limit] if params[:limit]
    flash[:s_keyword] = params[:s_keyword] if params[:s_keyword]
  end
  
end