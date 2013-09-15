class System::Admin::CommitmentsController < ApplicationController
  include System::Controller::Scaffold
  
  def initialize_scaffold
  end
  
  def index
    item = System::Commitment.new.readable
    item.page params[:page], params[:limit]
    @items = item.find(:all, :order => :id)
    _index @items
  end
  
  def show
    @item = System::Commitment.find(params[:id])
    #@item = System::Commitment.new.readable.find(params[:id])
    _show @item
  end

  def new
    @item = System::Commitment.new({
      :state      => 'enabled',
    })
  end
  
  def create
    @item = System::Commitment.new(params[:item])
    _create @item
  end
  
  def update
    @item = System::Commitment.new.find(params[:id])
    @item.attributes = params[:item]
    _update @item
  end
  
  def destroy
    @item = System::Commitment.new.find(params[:id])
    _destroy @item
  end
  
  def preview(item)
    render :text => item.value, :layout => 'empty'
  end
  
  def item_to_xml(item, options = {})
    options[:include] = [:status, :groups]
    xml = ''; xml << item.to_xml(options) do |n|
      #n << item.relation.to_xml(:root => 'relations', :skip_instruct => true, :include => [:group]) if item.relation
    end
    return xml
  end
end
