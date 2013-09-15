class Gw::Public::RssreaderController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
    return redirect_to(request.env['PATH_INFO']) if params[:reset]
  end

  def index

  end

  def edit_properties

  end

  def new
    hx = Gw::Model::UserProperty.get('feed')
    @item = hx.nil? ? {} : hx
  end

  def edit
    hu = Gw::Model::UserProperty.get('feed')
    hu['feeds'].each do |feed|
      if feed['id'].to_s==params[:id].to_s
        @item = feed
      end
    end
  end

  def create
    hu = Gw::Model::UserProperty.get('feed')
    next_id = 0
    if hu.nil?
      hu = {"version"=>1, "feeds"=>[]}
    else
      hu['feeds'].each {|f| next_id = f['id'].to_i if next_id < f['id'].to_i}
    end
    h_update = {'id'=> (next_id + 1).to_s}
    ['index','title','uri','max'].each {|x| h_update[x] = params[x]}
    hu['feeds'].push h_update
    ret = Gw::Model::UserProperty.save('feed', hu)
    if ret == true
      flash_notice('ユーザフィード追加処理', true)
      redirect_to '/gw/rssreader/edit_properties'
    else
      respond_to do |format|
        format.html {
          h_update['errors'] = ret
          @item = h_update
          render :action => "new"
        }
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    hu = Gw::Model::UserProperty.get('feed')
    idx = -1
    hu['feeds'].each do |feed|
      idx += 1
      if feed['id'].to_s == params["id"].to_s
        ['id','index','title','uri','max'].each do |x|
          hu['feeds'][idx][x] = params[x]
        end
      end
    end

    ret = Gw::Model::UserProperty.save('feed', hu)
    if ret == true
      flash_notice('ユーザフィード編集処理', true)
      redirect_to '/gw/rssreader/edit_properties'
    else
      respond_to do |format|
        format.html {
          h_update['errors'] = ret
          @item = h_update
          render :action => "edit"
        }
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    hu = Gw::Model::UserProperty.get('feed')
    idx = -1
    hu['feeds'].each do |feed|
      idx += 1
      if feed['id'].to_s == params["id"].to_s
        hu['feeds'].delete_at(idx)
      end
    end
    flash_notice('ユーザフィード削除処理', Gw::Model::UserProperty.save('feed', hu))
    redirect_to '/gw/rssreader/edit_properties'
  end
end
