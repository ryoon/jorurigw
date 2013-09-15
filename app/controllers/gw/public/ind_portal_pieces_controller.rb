class Gw::Public::IndPortalPiecesController < ApplicationController
  include System::Controller::Scaffold

  def index
    items = Gw::IndPortalPiece.get_user_items
    @main_items = items.select { |x| x.position == 'main' }
    @left_items = items.select { |x| x.position == 'left' }
    @setting = Gw::IndPortalSetting.read
    _index @main_items + @left_items
  end
  
  def show
    @item = Gw::IndPortalPiece.find(params[:id]) rescue nil
    return http_error(404) if @item.blank? || @item.uid != Site.user.id
    _show @item
  end
  
  def new
    return http_error(404) if params[:position].blank?
    position = params[:position]
    @item = Gw::IndPortalPiece.new
    return http_error(404) if @item.blank?
    @item.set_default
    @item.position = position
    @user_items, @cand_items = Gw::IndPortalPiece.get_user_cand_items(position)
    @setting = Gw::IndPortalSetting.read
  end
  
  def create
    @item = Gw::IndPortalPiece.new(params[:item])
    return http_error(404) if @item.blank?
    @user_items, @cand_items = Gw::IndPortalPiece.get_user_cand_items(params[:item][:position])
    return http_error(404) if @user_items.nil? || @cand_items.nil?
    data = params[:item][:name].split(/ /)
    if data.length >= 3
      @item.piece = data[0]
      @item.genre = data[1]
      @item.tid = data[2]
      @item.name = get_item_name(@item, @cand_items)
    else
      @item.piece = ""
      @item.genre = ""
      @item.tid = 0
      @item.name = ""
    end
    @setting = Gw::IndPortalSetting.read
    _create(@item, :success_redirect_uri => "#{Site.current_node.public_uri}")
  end
  
  def edit
    @item = Gw::IndPortalPiece.find(params[:id]) rescue nil
    return http_error(404) if @item.blank? || @item.uid != Site.user.id
    @user_items, @cand_items = Gw::IndPortalPiece.get_user_cand_items_with(@item, @item.position)
  end
  
  def update
    @item = Gw::IndPortalPiece.find(params[:id]) rescue nil
    return http_error(404) if @item.blank? || @item.uid != Site.user.id
    @item.attributes = params[:item]
    @user_items, @cand_items = Gw::IndPortalPiece.get_user_cand_items_with(@item, params[:item][:position])
    return http_error(404) if @user_items.nil? || @cand_items.nil?
    data = params[:item][:name].split(/ /)
    if data.length >= 3
      @item.piece = data[0]
      @item.genre = data[1]
      @item.tid = data[2]
      @item.name = get_item_name(@item, @cand_items)
    else
      @item.piece = ""
      @item.genre = ""
      @item.tid = 0
      @item.name = ""
    end
    _update(@item, :success_redirect_uri => "#{Site.current_node.public_uri}")
  end
  
  def destroy
    @item = Gw::IndPortalPiece.find(params[:id]) rescue nil
    return http_error(404) if @item.blank? || @item.uid != Site.user.id
    _destroy(@item, :success_redirect_uri => "#{Site.current_node.public_uri}")
  end
  
  def swap
    item1 = Gw::IndPortalPiece.find(params[:id]) rescue nil
    item2 = Gw::IndPortalPiece.find(params[:sid]) rescue nil
    return http_error(404) if item1.blank? || item1.uid != Site.user.id
    return http_error(404) if item2.blank? || item2.uid != Site.user.id
    Gw::IndPortalPiece.swap(item1, item2)
    redirect_to "#{Site.current_node.public_uri}"
  end
  
  def bookmark
    @items = Gw::IndPortalPiece.get_usable_items
    @items = @items.select {|x| x.board_piece? }  
    _index @items
  end
  
protected

  def get_item_name(item, cand_items)
    items = cand_items.select{|x| x.piece_name_for_select == item.piece_name_for_select}
    return "" if items.length == 0
    return items[0].name
  end
end