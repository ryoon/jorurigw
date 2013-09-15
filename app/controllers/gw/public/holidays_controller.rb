class Gw::Public::HolidaysController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
    return redirect_to(request.env['PATH_INFO']) if params[:reset]
    @css = %w(/_common/themes/gw/css/schedule.css)
    @category_id = nz(params[:category], 1).to_i rescue 1
    @hcs = Gw.yaml_to_array_for_select('gw_holiday_categories')
    @category_title = @hcs.rassoc(@category_id)[0]
  end

  def index
    order = "DATE_FORMAT( st_at, '%Y' ) DESC,st_at"
    @items = Gw::Holiday.find(:all, :conditions=>"coalesce(title_category_id,1)=#{@category_id}", :order=>order)
  end

  def show
    @item = Gw::Holiday.new.find(params[:id])
  end

  def new
    @item = Gw::Holiday.new({})
  end

  def edit
    @item = Gw::Holiday.new.find(params[:id])
  end

  def create
    u = Site.user; g = u.groups[0]
    params[:item][:st_at] = params[:item][:st_at] + " 00:00:00"
    item = params[:item].merge({
      :creator_uid => u.id,
      :creator_ucode => u.code,
      :creator_uname => u.name,
      :creator_gid => g.id,
      :creator_gcode => g.code,
      :creator_gname => g.name,
      :title_category_id => @category_id,
      :is_public => 1,
      :no_time_id => 1,
      :ed_at => params[:item][:st_at],
    })
    @item = Gw::Holiday.new(item)
    _create @item, :success_redirect_uri => "/gw/holidays?category=#{@category_id}", :notice => '休日の登録に成功しました'
  end

  def update
    @item = Gw::Holiday.find(params[:id])
    params[:item][:st_at] = params[:item][:st_at] + " 00:00:00"

    @item.attributes = params[:item].merge({
      :ed_at => params[:item][:st_at],
    })
    _update @item, :success_redirect_uri => "/gw/holidays?category=#{@category_id}", :notice => "休日の更新に成功しました"
  end

  def destroy
    @item = Gw::Holiday.find(params[:id])
    location = Gw.chop_with("#{Site.current_node.public_uri}",'/')
    _destroy(@item,:success_redirect_uri=>location)
  end

end
