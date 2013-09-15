class Pref::Admin::DocsController < ApplicationController
  include System::Controller::Scaffold
  include System::Controller::Scaffold::Recognition
  include System::Controller::Scaffold::Publication
  include System::Controller::Scaffold::Commitment
  
  def initialize_scaffold
    error_auth unless params[:content]
    error_auth unless @content = Cms::Content.find(params[:content])
  end
  
  def index
    item = Pref::Doc.new#.readable
    item.content_id = @content.id
    item.page  params[:page], params[:limit]
    item.order params[:sort], 'updated_at DESC'
    @items = item.find(:all)
    _index @items
  end
  
  def show
    @item = Pref::Doc.new.find(params[:id])
    return error_auth unless @item.readable?
    
    _show @item
  end

  def new
    @item = Pref::Doc.new({
      :state        => 'recognize',
      :notice_state => 'hidden',
      :recent_state => 'visible',
      :list_state   => 'visible',
      :event_state  => 'hidden',
    })
  end
  
  def create
    @item = Pref::Doc.new(params[:item])
    @item.content_id = @content.id
    _create @item
  end
  
  def update
    @item = Pref::Doc.new.find(params[:id])
    @item.attributes = params[:item]
    _update @item
  end
  
  def destroy
    @item = Pref::Doc.new.find(params[:id])
    _destroy @item
  end
  
  def clone(item, options = {})
    _clone = item.class.new
    _clone.attributes = item.attributes
    _clone.id            = nil
    _clone.unid          = nil
    _clone.created_at    = nil
    _clone.updated_at    = nil
    _clone.recognized_at = nil
    _clone.published_at  = nil
    _clone.state         = 'draft'
    _clone.name          = nil
    
    respond_to do |format|
      if _clone.save
        options[:after_process].call if options[:after_process]
        system_log.add(:item => item, :action => 'clone')
        
        flash[:notice] = options[:notice] || '複製処理が完了しました'
        format.html { redirect_to url_for(:action => :index) }
        format.xml  { head :ok }
      else
        #_clone.errors.each_full {|msg| dump msg }
        flash[:notice] = '複製できません'
        format.html { render :action => :show }
        format.xml  { render :xml => item.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def item_to_xml(item, options = {})
    options[:include] = [:status, :notice_status, :recent_status, :list_status, :categories, :publisher, :tasks]
    xml = ''; xml << item.to_xml(options) do |n|
      n.public_uri  item.public_uri
      n.preview_uri item.preview_uri
      n << item.file_groups.to_xml(:root => 'file_groups', :skip_instruct => true, :include => [:files],
        :dasherize => false) if item.file_groups
      n << item.creator.to_xml(:root => 'creator', :skip_instruct => true, :include => [:user, :group]) if item.creator
      n << item.recognizers.to_xml(:root => 'recognizers', :skip_instruct => true, :include => [:user]) if item.recognizers
      n << item.inquiry.to_xml(:root => 'inquiry', :skip_instruct => true, :include => [:group]) if item.inquiry
    end
    return xml
  end
end
