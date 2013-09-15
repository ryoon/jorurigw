class System::Admin::GroupNextsController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
    @current='updates'
    @group_update = params[:group_update]
    @group_updates = System::GroupUpdate.find(@group_update)

    item = System::GroupChange.new
    item.order "created_at DESC , updated_at DESC"
    @item_latest = item.find(:first)
    item = System::GroupChange.new
    item.state = '2'
    item.order "created_at DESC , updated_at DESC"
    @item_state2 = item.find(:first)
  end

  def index
    item = System::GroupNext.new
    item.group_update_id = params[:group_update]
    item.page  params[:page], params[:limit]
    item.order "old_code ASC"
    @items = item.find(:all)
    _index @items
  end
  def show
    @item = System::GroupNext.find(params[:id])
  end

  def new
    @item = System::GroupNext.new
    @item.group_update_id = @group_update
    @item.operation = '4'
  end
  def create
    @item = System::GroupNext.new(params[:item])
    options={}
    if @item_state2.blank?
      options[:after_process]=Proc.new{
        item_state2 = System::GroupChange.new
        item_state2.state       = '2'
        item_state2.updated_at  = Time.now
        item_state2.save
      }
    else
      options[:after_process]=Proc.new{
        item_state2 = System::GroupChange.find(@item_state2.id)
        item_state2.updated_at = Time.now
        item_state2.save
      }
    end
    _create @item,options
  end

  def edit
    @item = System::GroupNext.new.find(params[:id])
    @old_group_id = @item.old_group_id
  end
  def update
    @item = System::GroupNext.new.find(params[:id])
    @item.attributes = params[:item]
    options={}
    if @item_state2.blank?
      options[:after_process]=Proc.new{
        item_state2 = System::GroupChange.new
        item_state2.state       = '2'
        item_state2.updated_at  = Time.now
        item_state2.save
      }
    else
      options[:after_process]=Proc.new{
        item_state2 = System::GroupChange.find(@item_state2.id)
        item_state2.updated_at = Time.now
        item_state2.save
      }
    end
    _update @item,options
  end

  def destroy
    @item = System::GroupNext.new.find(params[:id])
    _destroy @item
  end

end
