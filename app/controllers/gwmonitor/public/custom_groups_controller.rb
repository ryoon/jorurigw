class Gwmonitor::Public::CustomGroupsController < ApplicationController

  include System::Controller::Scaffold
  include Gwmonitor::Controller::Systemname

  def initialize_scaffold
    @system_title = disp_system_name
    @css = ["/_common/themes/gw/css/monitor.css"]
    params[:limit] = 50
    @home_path = '/gwmonitor/custom_groups'
  end

  def index
    item = Gwmonitor::CustomGroup.new
    item.and :owner_uid , Site.user.id
    item.order 'sort_no, id'
    item.page params[:page], params[:limit]
    @items = item.find(:all)
  end

  def show

  end

  def new
    @item = Gwmonitor::CustomGroup.new({
      :state => 'enabled',
      :sort_no => 10
    })
  end

  def edit
    @item = Gwmonitor::CustomGroup.find(params[:id])
    return http_error(404) unless @item
    return authentication_error(403)  unless @item.owner_uid == Site.user.id

  end

  def create
    @item = Gwmonitor::CustomGroup.new(params[:item])
    @item.owner_uid = Site.user.id
    _create(@item, :success_redirect_uri=>@home_path)
  end

  def update
    @item = Gwmonitor::CustomGroup.find(params[:id])
    return http_error(404) unless @item
    return authentication_error(403)  unless @item.owner_uid == Site.user.id
    @item.attributes = params[:item]
    @item.owner_uid = Site.user.id
    _update(@item, :success_redirect_uri=>@home_path)
  end

  def destroy
    @item = Gwmonitor::CustomGroup.find(params[:id])
    return http_error(404) unless @item
    return authentication_error(403)  unless @item.owner_uid == Site.user.id
    _destroy(@item, :success_redirect_uri=>@home_path)
  end

  def sort_update
    @item = Gwmonitor::CustomGroup.new
    unless params[:item].blank?
      params[:item].each{|key,value|
        if /^[0-9]+$/ =~ value
        else
          @item.errors.add :"並び順"
          break
        end
      }
    end

    if @item.errors.size == 0
      unless params[:item].blank?
       params[:item].each{|key,value|
         cgid = key.slice(8, key.length - 7 ) #sort_no_* > *
         item = Gwmonitor::CustomGroup.new.find(cgid)
         item.sort_no = value
         item.save
       }
     end
     flash_notice 'カスタムグループの並び順更新', true
     redirect_to '/gwmonitor/custom_groups'
   else
      respond_to do |format|
        format.html { render :action => "index" }
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
   end
  end

end
