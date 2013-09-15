class Gw::Public::MemoSettingsController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold

  end

  def index
    @is_gw_admin = Gw.is_admin_admin?
  end

  def reminder
    key = 'memos'
    @item = Gw::Model::Schedule.get_settings key
  end

  def edit_reminder
    key = 'memos'
    _params = params[:item]
    hu = nz(Gw::Model::UserProperty.get(key.singularize), {})
    default = Gw::NameValue.get_cache('yaml', nil, "gw_#{key}_settings_system_default")

    hu[key] = {} if hu[key].nil?
    hu_update = hu[key]
    hu_update['read_memos_display']   = _params['read_memos_display']
    hu_update['unread_memos_display'] = _params['unread_memos_display']

    options = {}
    ret = Gw::Model::UserProperty.save(key.singularize, hu, options)
    if ret == true
      flash_notice('表示設定編集処理', true)
       redirect_to "/gw/memo_settings"
    else
      respond_to do |format|
        format.html {
          hu_update['errors'] = ret
          hu_update.merge!(default){|k, self_val, other_val| self_val}
          @item = hu[key]
          render :action => "reminder"
        }
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
    end
  end


  def admin_deletes
    key = 'memos'
    options = {}
    options[:class_id] = 3
    @item = Gw::Model::Schedule.get_settings key, options
  end

  def edit_admin_deletes
    key = 'memos'
    options = {}
    options[:class_id] = 3

    _params = params[:item]
    hu = nz(Gw::Model::UserProperty.get(key.singularize), {})
    default = Gw::NameValue.get_cache('yaml', nil, "gw_#{key}_settings_system_default")

    hu[key] = {} if hu[key].nil?
    hu_update = hu[key]
    hu_update['read_memos_admin_delete']   = _params['read_memos_admin_delete']
    hu_update['unread_memos_admin_delete']   = _params['unread_memos_admin_delete']

    ret = Gw::Model::UserProperty.save(key.singularize, hu, options)
    if ret == true
      flash_notice('連絡メモ削除設定処理', true)
       redirect_to "/gw/admin_settings"
    else
      respond_to do |format|
        format.html {
          hu_update['errors'] = ret
          hu_update.merge!(default){|k, self_val, other_val| self_val}
          @item = hu[key]
          render :action => "admin_deletes"
        }
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
    end
  end



end
