class Cms::Admin::Piece::LinksController < ApplicationController
  include System::Controller::Scaffold
  
  def initialize_scaffold
    id     = params[:piece] == '0' ? 1 : params[:piece]
    @piece = Cms::Piece.new.find(id)
  end
  
  def index
    item = Cms::PieceLink.new#.readable
    item.piece_id = @piece.id
    item.page  params[:page], params[:limit]
    item.order params[:sort], :sort_no
    @items = item.find(:all)
    _index @items
  end
  
  def show
    @item = Cms::PieceLink.new.find(params[:id])
    return error_auth unless @item.readable?
    
    _show @item
  end

  def new
    @item = Cms::PieceLink.new({
      :state      => 'public',
      :sort_no    => 0,
      :url        => 'http://',
      :target     => '',
    })
  end
  
  def create
    @item = Cms::PieceLink.new(params[:item])
    @item.piece_id = @piece.id
    _create @item
  end
  
  def update
    @item = Cms::PieceLink.new.find(params[:id])
    @item.attributes = params[:item]
    _update @item
  end
  
  def destroy
    @item = Cms::PieceLink.new.find(params[:id])
    _destroy @item
  end
  
  def item_to_xml(item, options = {})
    options[:include] = [:status, :publisher]
    xml = ''; xml << item.to_xml(options) do |n|
      n << item.creator.to_xml(:root => 'creator', :skip_instruct => true, :include => [:user, :group]) if item.creator
      n << item.recognizers.to_xml(:root => 'recognizers', :skip_instruct => true, :include => [:user]) if item.recognizers
    end
    return xml
  end
end
