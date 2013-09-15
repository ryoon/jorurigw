class Gw::Admin::IconsController < ApplicationController
  include System::Controller::Scaffold
  def index
    item = Gw::Icon.new
    item.page  params[:page], params[:limit]
    item.search params
    @items = item.find(:all)
  end
  def show
    @item = Gw::Icon.find(params[:id])
  end
  def new
    @item = Gw::Icon.new({})
  end
  def create
    params[:item][:icon_gid] = params[:igid]
    params[:item][:idx] = nz(Gw::Icon.find(:first, :select => 'max(idx) as maxid', :conditions => "icon_gid = #{params[:igid]}").maxid.to_i, 0) + 1
    file = params[:item][:upload]
    unless file.blank?
      params[:item][:title] = file.original_filename if params[:item][:title].blank?
      params[:item][:content_type] = file.content_type
      filename = "/_common/modules/gw_icons/#{params[:igid]}/#{params[:item][:idx]}#{File.extname file.original_filename}"
      params[:item][:path] = filename
      filepath = RAILS_ROOT
      filepath += '/' unless filepath.ends_with?('/')
      filepath += "public#{filename}"
      x = Gw.mkdir_for_file filepath
      unless x
        flash[:notice] = 'ディレクトリの作成に失敗しました'
        redirect_to gw_icons_path
      end
      File.open(filepath, 'wb') { |f| f.write file.read }
    end
    params[:item].delete :upload
    @item = Gw::Icon.new(params[:item])
    _create @item
  end
  def edit
    @item = Gw::Icon.find_by_id(params[:id])
  end
  def update
    @item = Gw::Icon.find(params[:id])
    file = params[:item][:upload]
    unless file.blank?
      params[:item][:title] = file.original_filename if params[:item][:title].blank?
      params[:item][:content_type] = file.content_type
      filename = "/_common/modules/gw_icons/#{params[:igid]}/#{params[:item][:idx]}.png"
      params[:item][:path] = filename
      filepath = RAILS_ROOT
      filepath += '/' unless filepath.ends_with?('/')
      filepath += "public#{filename}"
      File.open(filepath, 'wb') { |f| f.write file.read }
    end
    params[:item].delete :upload
    @item.attributes = params[:item]
    _update @item
  end
  def destroy
    @item = Gw::Icon.find(params[:id])
    _destroy @item
  end
end
