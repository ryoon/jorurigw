class Gw::Public::IndEditLinkPiecesController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
    pid = params[:pid] == '0' ? 1 : params[:pid]
    @parent = Gw::EditLinkPiece.find(pid) rescue nil
  end

  def index
    return http_error(404) if @parent.blank? || @parent.uid != Site.user.id
    item = Gw::EditLinkPiece.new
    cond  = "state != 'deleted' AND parent_id = #{@parent.id} AND uid = #{Site.user.id}"
    order = "sort_no ASC"
    @items = item.find(:all, :conditions => cond, :order => order)
    _index @items
  end

  def show
    return http_error(404) if @parent.blank? || @parent.uid != Site.user.id
    @item = Gw::EditLinkPiece.find(params[:id]) rescue nil
    return http_error(404) if @item.blank? || @item.deleted? || @item.uid != Site.user.id
    _show @item
  end

  def new
    return http_error(404) if @parent.blank? || @parent.uid != Site.user.id
    @item = Gw::EditLinkPiece.new
    @item.set_default_ind(@parent)
    return http_error(404) if @item.blank? || @item.deleted? || @item.uid != Site.user.id
  end

  def create
    return http_error(404) if @parent.blank? || @parent.uid != Site.user.id
    @item = Gw::EditLinkPiece.new(params[:item])
    return http_error(404) if @item.blank? || @item.deleted? || @item.uid != Site.user.id
    location = "#{Site.current_node.public_uri}?pid=#{@parent.id}"
    options = {
      :success_redirect_uri => location
    }
    _create @item, options
  end

  def edit
    return http_error(404) if @parent.blank? || @parent.uid != Site.user.id
    @item = Gw::EditLinkPiece.find(params[:id]) rescue nil
    return http_error(404) if @item.blank? || @item.deleted? || @item.uid != Site.user.id
  end

  def update
    return http_error(404) if @parent.blank? || @parent.uid != Site.user.id
    @item = Gw::EditLinkPiece.find(params[:id]) rescue nil
    return http_error(404) if @item.blank? || @item.deleted? || @item.uid != Site.user.id
    @item.attributes = params[:item]
    location = "#{Site.current_node.public_uri}#{@item.id}?pid=#{@parent.id}"
    options = {
      :success_redirect_uri => location
    }
    _update @item, options
  end

  def destroy
    return http_error(404) if @parent.blank? || @parent.uid != Site.user.id
    @item = Gw::EditLinkPiece.find(params[:id]) rescue nil
    return http_error(404) if @item.blank? || @item.deleted? || @item.uid != Site.user.id
    @item.save_deleted
    location = "#{Site.current_node.public_uri}?pid=#{@parent.id}"
    redirect_to location
  end

  def swap
    return http_error(404) if @parent.blank? || @parent.uid != Site.user.id
    item1 = Gw::EditLinkPiece.find(params[:id]) rescue nil
    item2 = Gw::EditLinkPiece.find(params[:sid]) rescue nil
    return http_error(404) if item1.blank? || item1.deleted? || item1.uid != Site.user.id
    return http_error(404) if item2.blank? || item2.deleted? || item2.uid != Site.user.id
    return http_error(404) if item1.parent.blank? || item2.parent.blank? || item1.parent.id != item2.parent.id
    Gw::EditLinkPiece.swap(item1, item2)
    location = "#{Site.current_node.public_uri}?pid=#{@parent.id}"
    redirect_to location
  end

  def list
    return http_error(404) if @parent.blank? || @parent.uid != Site.user.id
    item = Gw::EditLinkPiece.new
    cond  = "state != 'deleted' AND level_no = 2 AND uid = #{Site.user.id}"
    order = "state DESC, sort_no ASC"
    @items = item.find(:all, :order => order, :conditions => cond)
    _index @items
  end

  def fill_sso
    text = Gw::EditLinkPiece.get_sso_by_json(params[:ssoid])
    respond_to do |format|
      format.csv { render :text => text, :layout=>false, :locals=>{:f=>@item} }
    end
  end

  def bookmark
    @item = Gw::EditLinkPiece.create_bookmark_item(params[:title], params[:url])
    return http_error(404) if @item.blank? || @item.deleted? || @item.uid != Site.user.id
    if params[:redirect]
      redirect = params[:redirect]
      notice = "#{@item.name} をブックマークに追加しました。"
    else
      redirect = @item.link_url
      notice = ""
    end
    _create @item, :success_redirect_uri => redirect, :notice => notice
  end

protected

  def save_bookmark
    @item = Gw::EditLinkPiece.new(params[:item])
    return http_error(404) if @item.blank? || @item.deleted? || @item.uid != Site.user.id
    if @item.parent.blank?
      _bookmark @item, "/gw/ind_edit_link_pieces/bookmark"
    else
      @item.sort_no = Gw::EditLinkPiece.next_sort_no(@item.parent.id)
      _bookmark @item, "/gw/ind_edit_link_pieces?pid=#{@item.parent.id}"
    end
  end

  def _bookmark(item, location)
    respond_to do |format|
      if item.creatable? && item.save
        system_log.add(:item => item, :action => 'create')
        flash[:notice] = '登録処理が完了しました'
        format.html { redirect_to location }
        format.xml  { render :xml => to_xml(item), :status => status, :location => location }
      else
        format.html { render :action => "bookmark" }
        format.xml  { render :xml => item.errors, :status => :unprocessable_entity }
      end
    end
  end
end