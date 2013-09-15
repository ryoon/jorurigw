class System::Admin::GroupChangePickupsController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
    @current='pickups'
    flash[:notice]=""

    item = System::GroupChange.new
    item.order "created_at DESC , updated_at DESC"
    @item_latest=item.find(:first)
    rtn = System::GroupChange.check_sequence(@item_latest,'set_pickup')
    if rtn == false
        flash[:notice] = "実行順序が違っています。"
        redirect_to system_group_changes_path
        return
    end

    item = System::GroupChange.new
    item.state = '5'
    item.order "created_at DESC , updated_at DESC"
    @item_state2 = item.find(:first)
  end

  def index
      item = System::GroupChangePickup.new
      item.page  params[:page], params[:limit]
      item.order "updated_at DESC"
      @items = item.find(:all)
      _index @items
  end

  def show
      @item = System::GroupChangePickup.new.find(params[:id])
  end

  def new
      @item = System::GroupChangePickup.new
#      @item.target_at = Date.today
      current_date = Date.today
      next_date = current_date >> 1
      start_date = next_date.year.to_s + '-' + next_date.month.to_s + '-1'
      @item.target_at = start_date
  end
  def create
      @item = System::GroupChangePickup.new(params[:item])
    options={}
    options[:after_process]=Proc.new{
      System::GroupChange.make_record(@item_state2,'set_pickup')
    }
    _create @item,options
#      _create @item
  end

  def edit
      @item = System::GroupChangePickup.new.find(params[:id])
  end
  def update
      @item = System::GroupChangePickup.new.find(params[:id])
      @item.attributes = params[:item]
    options={}
    options[:after_process]=Proc.new{
      System::GroupChange.make_record(@item_state2,'set_pickup')
    }
      _update @item,options
  end

  def destroy
    redirect_to :action=>:index
  end
end
