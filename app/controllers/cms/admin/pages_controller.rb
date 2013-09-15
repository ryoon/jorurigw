class Cms::Admin::PagesController < ApplicationController
  include System::Controller::Scaffold
  include System::Controller::Scaffold::Recognition
  include System::Controller::Scaffold::Publication
  include System::Controller::Scaffold::Commitment

  def initialize_scaffold
    id      = params[:parent] == '0' ? 1 : params[:parent]
    @parent = Cms::Node.new.find(id)
  end

  def index
    item = Cms::Page.new#.readable
    item.node_id = @parent.id
    item.page  params[:page], params[:limit]
    item.order params[:sort], :name
    @items = item.find(:all)
    _index @items
  end

  def show
    @item = Cms::Page.new.find(params[:id])
    return error_auth unless @item.readable?

    _show @item
  end

  def new
    @item = Cms::Page.new({
      :state      => 'recognize',
      :node_id    => @parent.id,
      :layout_id  => @parent.layout_id,
      :name       => 'index.html',
      :title      => 'ページ',
      :body       => 'ここにページの内容を書いてください',
    })
  end

  def create
    @item = Cms::Page.new(params[:item])
    @item.node_id = @parent.id

    case params[:input_mode]
    when 'h'
      create_by_html
    when 'u'
      create_by_url
    else
      _create @item
    end
  end

  def create_error(msg)
    @item.errors.add_to_base msg
    respond_to do |format|
      format.html { render :action => :new }
      format.xml  { render :xml => item.errors, :status => :unprocessable_entity }
    end
  end

  def create_by_html
    if params[:item][:import_data].to_s == ''
      return create_error('HTMLファイルを入力してください')
    end

    content = params[:item][:import_data].read
    content = NKF::nkf('-w', content)
    @item.state = 'draft'
    @item.body  = content.gsub(/.*<body.*?>(.*?)<\/body.*/im, '\1')

    _create @item
  end

  def create_by_url
    uri = params[:item][:import_data]
    if uri.to_s == ''
      return create_error('URLを入力してください')
    end

    req = Util::Http::Request.new
    res = req.send(uri)

    if res[:status] != 200
      return create_error('HTMLファイルを取得できませんでした')
    end

    content = NKF.nkf('-w', res[:body])
    @item.state = 'draft'
    @item.body  = content.gsub(/.*<body.*?>(.*?)<\/body.*/im, '\1')

    _create @item
  end

  def update
    @item = Cms::Page.new.find(params[:id])
    @item.attributes = params[:item]
    _update @item
  end

  def destroy
    @item = Cms::Page.new.find(params[:id])
    _destroy @item
  end

  def item_to_xml(item, options = {})
    options[:include] = [:status, :publisher, :tasks]
    xml = ''; xml << item.to_xml(options) do |n|
      n.public_uri  item.public_uri
      n.preview_uri item.preview_uri
      n << item.creator.to_xml(:root => 'creator', :skip_instruct => true, :include => [:user, :group]) if item.creator
      n << item.recognizers.to_xml(:root => 'recognizers', :skip_instruct => true, :include => [:user]) if item.recognizers
      n << item.inquiry.to_xml(:root => 'inquiry', :skip_instruct => true, :include => [:group]) if item.inquiry
    end
    return xml
  end
end
