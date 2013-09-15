class Gwcircular::Public::CustomGroupsController < ApplicationController

  include Gwboard::Controller::Scaffold
  include Gwcircular::Model::DbnameAlias
  include Gwboard::Controller::Authorize
  include Gwboard::Controller::Message

  def initialize_scaffold
    params[:title_id] = 1
    @title = Gwcircular::Control.find_by_id(params[:title_id])
    return http_error(404) unless @title

    @css = ["/_common/themes/gw/css/circular.css"]
    params[:limit] = 200
  end

  def index
    get_role_index
    return authentication_error(403) unless @is_readable

    item = Gwcircular::CustomGroup.new
    item.and :owner_uid , Site.user.id
    item.order 'sort_no, id'
    item.page params[:page], params[:limit]
    @items = item.find(:all)
  end

  def show

  end

  def new
    @item = Gwcircular::CustomGroup.new({
      :state => 'enabled',
      :sort_no => 10
    })
  end

  def edit
    get_role_new
    return authentication_error(403) unless @is_writable
    @item = Gwcircular::CustomGroup.find(params[:id])
    return http_error(404) unless @item
    return authentication_error(403)  unless @item.owner_uid == Site.user.id
  end

  def create
    get_role_index
    return authentication_error(403) unless @is_readable
    @item = Gwcircular::CustomGroup.new(params[:item])
    @item.owner_uid = Site.user.id
    _create @item
  end

  def update
    get_role_new
    return authentication_error(403) unless @is_writable
    @item = Gwcircular::CustomGroup.find(params[:id])
    return http_error(404) unless @item
    return authentication_error(403)  unless @item.owner_uid == Site.user.id
    @item.attributes = params[:item]
    @item.owner_uid = Site.user.id
    _update(@item)
  end

  def destroy
    get_role_new
    return authentication_error(403) unless @is_writable
    @item = Gwcircular::CustomGroup.find(params[:id])
    return http_error(404) unless @item
    return authentication_error(403)  unless @item.owner_uid == Site.user.id
    _destroy(@item)
  end

  def sort_update
    @item = Gwcircular::CustomGroup.new
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
         item = Gwcircular::CustomGroup.new.find(cgid)
         item.sort_no = value
         item.save
       }
     end
     flash_notice 'カスタムグループの並び順更新', true
     redirect_to '/gwcircular/custom_groups'
   else
      respond_to do |format|
        format.html { render :action => "index" }
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
   end
  end

end
