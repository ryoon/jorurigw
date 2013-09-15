class Cms::Admin::FilesController < ApplicationController
  include System::Controller::Scaffold
  
  def initialize_scaffold
    self.class.layout 'admin/base'
    
    @parent   = params[:parent]
  end
  
  def index
    @item = Cms::File.new#.readable
    @item.page  params[:page], params[:limit]
    @item.order params[:sort], :name
    @item.and :parent_unid, @parent
    @items = @item.find(:all)
    _index @items
  end
  
  def show
    @item = Cms::File.new.find(params[:id])
    return error_auth unless @item.readable?
    
    _show @item
  end

  def new
    @item = Cms::File.new({
    })
  end
  
  def create
    @item = Cms::File.new(params[:item])
    @item.parent_unid   = @parent
    _create @item
  end
  
  def update
    @item = Cms::File.new.find(params[:id])
    @item.attributes = params[:item]
    _update @item
  end
  
  def destroy
    @item = Cms::File.new.find(params[:id])
    _destroy @item
  end
  
  def download
    self.class.layout 'admin/base'
    
    item = Cms::File.new
    item.and :parent_unid, params[:parent]
    item.and :name, params[:name] + '.' + params[:format]
    return error_auth unless @file = item.find(:first)
    
    f = open(@file.upload_path)
    send_data(f.read, {:type => @file.mime_type, :filename => @file.name, :disposition => 'inline'})
    f.close
  end
  
#  def item_to_xml(item, options = {})
#    options[:include] = [:status, :publisher]
#    xml = ''; xml << item.to_xml(options) do |n|
#      n << item.creator.to_xml(:root => 'creator', :skip_instruct => true, :include => [:user, :group]) if item.creator
#      n << item.recognizers.to_xml(:root => 'recognizers', :skip_instruct => true, :include => [:user]) if item.recognizers
#    end
#    return xml
#  end
end
