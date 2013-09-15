class Cms::Admin::TmpFilesController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
    self.class.layout 'admin/base'

    @tmp   = params[:tmp]
  end

  def index
    @item = Cms::TmpFile.new#.readable
    @item.and :tmp_id, @tmp
    @item.page  params[:page], params[:limit]
    @item.order params[:sort], :name
    @items = @item.find(:all)
    _index @items
  end

  def show
    @item = Cms::TmpFile.new.find(params[:id])
    return error_auth unless @item.readable?

    _show @item
  end

  def new
    @item = Cms::TmpFile.new({
    })
  end

  def create
    @item = Cms::TmpFile.new(params[:item])
    @item.tmp_id   = @tmp
    _create @item
  end

  def update
    @item = Cms::TmpFile.new.find(params[:id])
    @item.attributes = params[:item]
    _update @item
  end

  def destroy
    @item = Cms::TmpFile.new.find(params[:id])
    _destroy @item
  end

  def download
    self.class.layout 'admin/base'

    item = Cms::TmpFile.new
    item.and :tmp_id, params[:tmp]
    item.and :name, params[:name] + '.' + params[:format]
    return error_auth unless @file = item.find(:first)

    f = open(@file.upload_path)
    send_data(f.read, {:type => @file.mime_type, :filename => @file.name, :disposition => 'inline'})
    f.close
  end

end
